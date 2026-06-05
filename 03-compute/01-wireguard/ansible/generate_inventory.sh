#!/usr/bin/env bash
set -euo pipefail

WIREGUARD_TF_DIR=".."
NETWORK_TF_DIR="../../../01-network"

tf_map_value() {
  local output_name="$1"
  local key="$2"

  terraform -chdir="${WIREGUARD_TF_DIR}" output -json "${output_name}" | jq -r --arg key "${key}" '.[$key]'
}

normalize_private_key_path() {
  local private_key_file="$1"

  if [[ "${private_key_file}" =~ ^/ || "${private_key_file}" =~ ^[A-Za-z]: ]]; then
    echo "${private_key_file}"
  else
    echo "${NETWORK_TF_DIR}/${private_key_file#./}"
  fi
}

PRIVATE_KEY_FILE="$(terraform -chdir="${NETWORK_TF_DIR}" output -raw boce_private_key_file)"
PRIVATE_KEY_FILE="$(normalize_private_key_path "${PRIVATE_KEY_FILE}")"
AWS_REGION="$(terraform -chdir="${WIREGUARD_TF_DIR}" output -raw aws_region 2>/dev/null || echo "ap-northeast-2")"

CARD_WG_01_PUBLIC_IP="$(tf_map_value wireguard_public_ips card-wireguard-01)"
CARD_WG_02_PUBLIC_IP="$(tf_map_value wireguard_public_ips card-wireguard-02)"
SECURITIES_WG_01_PUBLIC_IP="$(tf_map_value wireguard_public_ips securities-wireguard-01)"
SECURITIES_WG_02_PUBLIC_IP="$(tf_map_value wireguard_public_ips securities-wireguard-02)"

CARD_WG_01_PRIVATE_IP="$(tf_map_value wireguard_private_ips card-wireguard-01)"
CARD_WG_02_PRIVATE_IP="$(tf_map_value wireguard_private_ips card-wireguard-02)"
SECURITIES_WG_01_PRIVATE_IP="$(tf_map_value wireguard_private_ips securities-wireguard-01)"
SECURITIES_WG_02_PRIVATE_IP="$(tf_map_value wireguard_private_ips securities-wireguard-02)"

CARD_WG_01_INSTANCE_ID="$(tf_map_value wireguard_instance_ids card-wireguard-01)"
CARD_WG_02_INSTANCE_ID="$(tf_map_value wireguard_instance_ids card-wireguard-02)"
SECURITIES_WG_01_INSTANCE_ID="$(tf_map_value wireguard_instance_ids securities-wireguard-01)"
SECURITIES_WG_02_INSTANCE_ID="$(tf_map_value wireguard_instance_ids securities-wireguard-02)"

CARD_WG_01_ENI_ID="$(tf_map_value wireguard_primary_network_interface_ids card-wireguard-01)"
CARD_WG_02_ENI_ID="$(tf_map_value wireguard_primary_network_interface_ids card-wireguard-02)"
SECURITIES_WG_01_ENI_ID="$(tf_map_value wireguard_primary_network_interface_ids securities-wireguard-01)"
SECURITIES_WG_02_ENI_ID="$(tf_map_value wireguard_primary_network_interface_ids securities-wireguard-02)"

CARD_ROUTE_TABLE_ID="$(tf_map_value wireguard_route_table_ids card)"
SECURITIES_ROUTE_TABLE_ID="$(tf_map_value wireguard_route_table_ids securities)"

cat > inventory.yml <<EOF
all:
  children:
    wireguard:
      children:
        card_wireguard:
          hosts:
            card_wg_01:
              ansible_host: ${CARD_WG_01_PUBLIC_IP}
              ansible_user: ubuntu
              ansible_ssh_private_key_file: ${PRIVATE_KEY_FILE}
              wg_name: card_wg_01
              wg_address: 172.16.101.1
              wg_peer_tunnel_ip: 172.16.101.2
              wg_peer_lan_cidr: 10.1.100.0/24
              wg_peer_public_key: Rh+q4QHcNkdh19cb18+bqgmcKJYnYqkb2RSTG4Ovmgo=

              ha_name: A
              ha_my_eni: ${CARD_WG_01_ENI_ID}
              ha_my_vm_ip: 10.1.100.61
              ha_peer_name: B
              ha_peer_eni: ${CARD_WG_02_ENI_ID}
              ha_peer_instance_id: ${CARD_WG_02_INSTANCE_ID}
              ha_peer_private_ip: ${CARD_WG_02_PRIVATE_IP}
              ha_route_table_id: ${CARD_ROUTE_TABLE_ID}
              ha_dest_cidr: 10.1.100.0/24

            card_wg_02:
              ansible_host: ${CARD_WG_02_PUBLIC_IP}
              ansible_user: ubuntu
              ansible_ssh_private_key_file: ${PRIVATE_KEY_FILE}
              wg_name: card_wg_02
              wg_address: 172.16.102.1
              wg_peer_tunnel_ip: 172.16.102.2
              wg_peer_lan_cidr: 10.1.100.0/24
              wg_peer_public_key: yNpWbRoG9/oqnPJiFRzwIk2pe62nkbCFf4It9GljTVU=

              ha_name: B
              ha_my_eni: ${CARD_WG_02_ENI_ID}
              ha_my_vm_ip: 10.1.100.62
              ha_peer_name: A
              ha_peer_eni: ${CARD_WG_01_ENI_ID}
              ha_peer_instance_id: ${CARD_WG_01_INSTANCE_ID}
              ha_peer_private_ip: ${CARD_WG_01_PRIVATE_IP}
              ha_route_table_id: ${CARD_ROUTE_TABLE_ID}
              ha_dest_cidr: 10.1.100.0/24

        securities_wireguard:
          hosts:
            securities_wg_01:
              ansible_host: ${SECURITIES_WG_01_PUBLIC_IP}
              ansible_user: ubuntu
              ansible_ssh_private_key_file: ${PRIVATE_KEY_FILE}
              wg_name: securities_wg_01
              wg_address: 172.16.201.1
              wg_peer_tunnel_ip: 172.16.201.2
              wg_peer_lan_cidr: 10.1.200.0/24
              wg_peer_public_key: OzqwZr89h0zVpeKcF9mAXc4QfvVSR2QmfQnDQXSrugs=

              ha_name: A
              ha_my_eni: ${SECURITIES_WG_01_ENI_ID}
              ha_my_vm_ip: 10.1.200.61
              ha_peer_name: B
              ha_peer_eni: ${SECURITIES_WG_02_ENI_ID}
              ha_peer_instance_id: ${SECURITIES_WG_02_INSTANCE_ID}
              ha_peer_private_ip: ${SECURITIES_WG_02_PRIVATE_IP}
              ha_route_table_id: ${SECURITIES_ROUTE_TABLE_ID}
              ha_dest_cidr: 10.1.200.0/24

            securities_wg_02:
              ansible_host: ${SECURITIES_WG_02_PUBLIC_IP}
              ansible_user: ubuntu
              ansible_ssh_private_key_file: ${PRIVATE_KEY_FILE}
              wg_name: securities_wg_02
              wg_address: 172.16.202.1
              wg_peer_tunnel_ip: 172.16.202.2
              wg_peer_lan_cidr: 10.1.200.0/24
              wg_peer_public_key: MeZr3b8Rq8Hp/UriavUA2zfpE9OoJIVWDeg3eQtwcFk=

              ha_name: B
              ha_my_eni: ${SECURITIES_WG_02_ENI_ID}
              ha_my_vm_ip: 10.1.200.62
              ha_peer_name: A
              ha_peer_eni: ${SECURITIES_WG_01_ENI_ID}
              ha_peer_instance_id: ${SECURITIES_WG_01_INSTANCE_ID}
              ha_peer_private_ip: ${SECURITIES_WG_01_PRIVATE_IP}
              ha_route_table_id: ${SECURITIES_ROUTE_TABLE_ID}
              ha_dest_cidr: 10.1.200.0/24
      vars:
        ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
        ha_aws_region: ${AWS_REGION}
EOF

echo "inventory.yml generated."
