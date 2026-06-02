# AI DB Ansible

Run this directory from the card or securities Ansible bastion server.

```bash
cd /home/ubuntu/ansible/ai_db
./run-ai-db-ansible.sh
```

Targets are generated per VPC by the bastion bootstrap playbook:

- card: MySQL `10.11.41.81`, Neo4j `10.11.41.82`
- securities: MySQL `10.21.41.81`, Neo4j `10.21.41.82`

Change the passwords in `group_vars/ai_db.yml` before production use.
