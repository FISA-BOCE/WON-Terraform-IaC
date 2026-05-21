#!/usr/bin/env bash
set -euo pipefail

source /etc/wg-ha.env

STATE_DIR="/var/lib/wg-ha"
LOCK_FILE="/var/lock/wg-ha.lock"

MY_VM_FAIL_COUNT_FILE="${STATE_DIR}/my_vm_fail_count"
PEER_PING_FAIL_COUNT_FILE="${STATE_DIR}/peer_ping_fail_count"
LAST_SWITCH_FILE="${STATE_DIR}/last_switch"

mkdir -p "$STATE_DIR"

export AWS_MAX_ATTEMPTS=2
export AWS_RETRY_MODE=standard

log() {
  echo "$(date '+%F %T') [$MY_NAME] $*"
}

read_count() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cat "$file"
  else
    echo 0
  fi
}

inc_count() {
  local file="$1"
  local count
  count="$(read_count "$file")"
  count=$((count + 1))
  echo "$count" > "$file"
  echo "$count"
}

reset_count() {
  local file="$1"
  echo 0 > "$file"
}

ping_ok() {
  local target_ip="$1"
  ping -c 1 -W 1 "$target_ip" >/dev/null 2>&1
}

get_current_route_target() {
  aws ec2 describe-route-tables \
    --region "$REGION" \
    --route-table-ids "$ROUTE_TABLE_ID" \
    --query "RouteTables[0].Routes[?DestinationCidrBlock=='$DEST_CIDR'].NetworkInterfaceId | [0]" \
    --output text 2>/dev/null
}

peer_aws_status() {
  aws ec2 describe-instance-status \
    --region "$REGION" \
    --instance-ids "$PEER_INSTANCE_ID" \
    --include-all-instances \
    --query "InstanceStatuses[0].[InstanceState.Name,SystemStatus.Status,InstanceStatus.Status]" \
    --output text 2>/dev/null || echo "unknown unknown unknown"
}

peer_is_unhealthy_by_aws() {
  local status
  local instance_state
  local system_status
  local instance_status

  status="$(peer_aws_status)"
  instance_state="$(echo "$status" | awk '{print $1}')"
  system_status="$(echo "$status" | awk '{print $2}')"
  instance_status="$(echo "$status" | awk '{print $3}')"

  log "Peer AWS status: instance_state=${instance_state}, system_status=${system_status}, instance_status=${instance_status}"

  if [[ "$instance_state" != "running" ]]; then
    return 0
  fi

  if [[ "$system_status" == "impaired" || "$instance_status" == "impaired" ]]; then
    return 0
  fi

  return 1
}

in_cooldown() {
  if [[ ! -f "$LAST_SWITCH_FILE" ]]; then
    return 1
  fi

  local now
  local last
  local diff

  now="$(date +%s)"
  last="$(cat "$LAST_SWITCH_FILE")"
  diff=$((now - last))

  [[ "$diff" -lt "$COOLDOWN_SECONDS" ]]
}

switch_route_safely() {
  local expected_current_target="$1"
  local new_target_eni="$2"
  local reason="$3"

  if in_cooldown; then
    log "Cooldown active. Skip route change. reason=${reason}"
    return 0
  fi

  local current_target
  current_target="$(get_current_route_target)"

  log "Pre-switch route recheck: current=${current_target}, expected=${expected_current_target}, new=${new_target_eni}"

  if [[ "$current_target" != "$expected_current_target" ]]; then
    log "Route target already changed by another node. Skip."
    return 0
  fi

  log "Changing route: ${DEST_CIDR} -> ${new_target_eni}. reason=${reason}"

  aws ec2 replace-route \
    --region "$REGION" \
    --route-table-id "$ROUTE_TABLE_ID" \
    --destination-cidr-block "$DEST_CIDR" \
    --network-interface-id "$new_target_eni"

  date +%s > "$LAST_SWITCH_FILE"

  log "Route changed successfully: ${DEST_CIDR} -> ${new_target_eni}"
}

check_my_vm() {
  if ping_ok "$MY_VM_IP"; then
    reset_count "$MY_VM_FAIL_COUNT_FILE"
    return 0
  fi

  local fail_count
  fail_count="$(inc_count "$MY_VM_FAIL_COUNT_FILE")"

  log "My VM ping failed: target=${MY_VM_IP}, fail_count=${fail_count}/${PING_FAIL_THRESHOLD}"

  if [[ "$fail_count" -lt "$PING_FAIL_THRESHOLD" ]]; then
    return 0
  fi

  local current_target
  current_target="$(get_current_route_target)"

  log "My VM failed threshold reached. Current route target=${current_target}"

  if [[ "$current_target" == "$MY_ENI" ]]; then
    log "I am Active and my VM/tunnel seems unhealthy. Failover to peer ENI."
    switch_route_safely "$MY_ENI" "$PEER_ENI" "my_vm_ping_failed"
    reset_count "$MY_VM_FAIL_COUNT_FILE"
  elif [[ "$current_target" == "$PEER_ENI" ]]; then
    log "I am Standby and my VM ping failed. No route change."
  else
    log "Unknown route target=${current_target}. No route change."
  fi
}

check_peer_ec2() {
  if ping_ok "$PEER_PRIVATE_IP"; then
    reset_count "$PEER_PING_FAIL_COUNT_FILE"
    return 0
  fi

  local fail_count
  fail_count="$(inc_count "$PEER_PING_FAIL_COUNT_FILE")"

  log "Peer EC2 ping failed: peer=${PEER_NAME}, ip=${PEER_PRIVATE_IP}, fail_count=${fail_count}/${PING_FAIL_THRESHOLD}"

  if [[ "$fail_count" -lt "$PING_FAIL_THRESHOLD" ]]; then
    return 0
  fi

  local current_target
  current_target="$(get_current_route_target)"

  log "Peer ping failed threshold reached. Current route target=${current_target}"

  if [[ "$current_target" == "$PEER_ENI" ]]; then
    log "Peer is Active but peer ping failed. Check AWS status."

    if peer_is_unhealthy_by_aws; then
      log "AWS also says peer is unhealthy. Take over route to my ENI."
      switch_route_safely "$PEER_ENI" "$MY_ENI" "peer_ec2_unhealthy"
      reset_count "$PEER_PING_FAIL_COUNT_FILE"
    else
      if [[ "${TAKEOVER_ON_PEER_PING_FAIL_WHEN_AWS_OK}" == "true" ]]; then
        log "AWS says peer may be running, but peer ping failed. Takeover is allowed by config."
        switch_route_safely "$PEER_ENI" "$MY_ENI" "peer_ping_failed_even_aws_ok"
        reset_count "$PEER_PING_FAIL_COUNT_FILE"
      else
        log "AWS does not confirm peer failure. No route change."
      fi
    fi

  elif [[ "$current_target" == "$MY_ENI" ]]; then
    log "I am Active and Standby peer ping failed. No route change."
  else
    log "Unknown route target=${current_target}. No route change."
  fi
}

main() {
  exec 9>"$LOCK_FILE"
  flock -n 9 || {
    log "Previous check is still running. Exit."
    exit 0
  }

  check_my_vm
  check_peer_ec2
}

main
