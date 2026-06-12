# Redis Sentinel Ansible

Run this directory from the card or securities Ansible bastion server.

```bash
cd /home/ubuntu/ansible/redis
./run-redis-ansible.sh
```

Targets are generated per VPC by the bastion bootstrap playbook:

- card: `10.11.31.101`, `10.11.31.102`, `10.11.32.103`
- securities: `10.21.31.101`, `10.21.31.102`, `10.21.32.103`

Update `group_vars/redis.yml` with the real Redis password before production use.
