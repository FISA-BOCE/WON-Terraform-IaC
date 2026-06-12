module "redis_sentinel" {
  for_each = var.redis_networks

  source = "./modules/redis-sentinel"

  project                     = var.project
  env                         = var.env
  network_key                 = each.key
  vpc_id                      = data.terraform_remote_state.network.outputs.vpc_ids[each.value.vpc_key]
  ami_id                      = var.redis_ami_id
  instance_type               = var.redis_instance_type
  key_name                    = data.terraform_remote_state.network.outputs.boce_key_pair_name
  associate_public_ip_address = false
  root_volume_size            = var.redis_root_volume_size
  root_volume_type            = var.redis_root_volume_type
  redis_port                  = var.redis_port
  sentinel_port               = var.redis_sentinel_port
  sentinel_master_name        = each.value.sentinel_master_name

  nodes = local.redis_nodes_by_network[each.key]

  allowed_source_security_group_ids = compact([
    try(data.terraform_remote_state.app_infra.outputs.app_security_group_ids[each.key], null),
    try(data.terraform_remote_state.eks.outputs.eks_cluster_security_group_ids[each.key], null)
  ])

  ssh_allowed_cidrs              = each.value.ssh_allowed_cidrs
  ssh_allowed_security_group_ids = each.value.ssh_allowed_security_group_ids

  tags = var.default_tags
}
