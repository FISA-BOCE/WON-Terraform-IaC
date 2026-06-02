# Ansible Bastion Setup

This playbook installs Ansible on the three Ansible bastion EC2 instances.

## Prerequisites

- Apply `01-network`
- Apply `02-security`
- Apply `03-compute/99-bastion-ansible`
- Run from an environment with `terraform`, `ansible`, and `jq` for the shell script

## Generate Inventory

PowerShell:

```powershell
.\generate_inventory.ps1
```

Bash:

```bash
./generate_inventory.sh
```

## Run

```bash
ansible-playbook playbook.yml
```

