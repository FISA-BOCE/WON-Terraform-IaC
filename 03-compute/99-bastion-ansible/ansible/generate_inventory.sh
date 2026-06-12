#!/usr/bin/env bash
set -euo pipefail

COMPUTE_TF_DIR=".."
NETWORK_TF_DIR="../../../01-network"

tf_map_value() {
  local output_name="$1"
  local key="$2"

  terraform -chdir="${COMPUTE_TF_DIR}" output -json "${output_name}" | jq -r --arg key "${key}" '.[$key]'
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

CARD_PUBLIC_IP="$(tf_map_value ansible_bastion_public_ips card-ansible-bastion-server)"
SECURITIES_PUBLIC_IP="$(tf_map_value ansible_bastion_public_ips securities-ansible-bastion-server)"
COMMON_PUBLIC_IP="$(tf_map_value ansible_bastion_public_ips common-ansible-bastion-server)"

CARD_PRIVATE_IP="$(tf_map_value ansible_bastion_private_ips card-ansible-bastion-server)"
SECURITIES_PRIVATE_IP="$(tf_map_value ansible_bastion_private_ips securities-ansible-bastion-server)"
COMMON_PRIVATE_IP="$(tf_map_value ansible_bastion_private_ips common-ansible-bastion-server)"

cat > inventory.yml <<EOF
all:
  children:
    ansible_bastion:
      hosts:
        card_ansible_bastion:
          ansible_host: ${CARD_PUBLIC_IP}
          private_ip: ${CARD_PRIVATE_IP}
          vpc: card
        securities_ansible_bastion:
          ansible_host: ${SECURITIES_PUBLIC_IP}
          private_ip: ${SECURITIES_PRIVATE_IP}
          vpc: securities
        common_ansible_bastion:
          ansible_host: ${COMMON_PUBLIC_IP}
          private_ip: ${COMMON_PRIVATE_IP}
          vpc: common
      vars:
        ansible_user: ubuntu
        ansible_ssh_private_key_file: '${PRIVATE_KEY_FILE}'
        ansible_ssh_common_args: "-o StrictHostKeyChecking=no"
EOF

echo "inventory.yml generated."
