resource "aws_eks_cluster" "this" {
  for_each = local.eks_clusters

  name     = each.value.cluster_name
  role_arn = aws_iam_role.eks_cluster[each.key].arn
  version  = var.eks_cluster_version

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = local.eks_cluster_subnet_ids[each.key]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = merge(var.default_tags, {
    Name = each.value.cluster_name
    Vpc  = each.value.vpc_key
  })
}

resource "aws_security_group_rule" "eks_cluster_sg_ingress_from_vpc" {
  for_each = local.eks_clusters

  type              = "ingress"
  security_group_id = aws_eks_cluster.this[each.key].vpc_config[0].cluster_security_group_id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [
    data.terraform_remote_state.network.outputs.vpc_cidrs[each.value.vpc_key]
  ]

  description = "Allow internal VPC traffic to EKS cluster security group"
}

resource "aws_eks_node_group" "workload" {
  for_each = local.eks_clusters

  cluster_name    = aws_eks_cluster.this[each.key].name
  node_group_name = each.value.node_group_name
  node_role_arn   = aws_iam_role.eks_node[each.key].arn
  subnet_ids      = local.eks_cluster_subnet_ids[each.key]

  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  labels = {
    role = "workload"
  }

  tags = merge(var.default_tags, {
    Name = each.value.node_group_name
    Vpc  = each.value.vpc_key
    Role = "workload"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_readonly
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  for_each = local.eks_clusters

  cluster_name = aws_eks_cluster.this[each.key].name
  addon_name   = "vpc-cni"

  depends_on = [
    aws_eks_node_group.workload
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  for_each = local.eks_clusters

  cluster_name = aws_eks_cluster.this[each.key].name
  addon_name   = "kube-proxy"

  depends_on = [
    aws_eks_node_group.workload
  ]
}

resource "aws_eks_addon" "coredns" {
  for_each = local.eks_clusters

  cluster_name = aws_eks_cluster.this[each.key].name
  addon_name   = "coredns"

  depends_on = [
    aws_eks_node_group.workload
  ]
}

resource "aws_ec2_tag" "eks_cluster_subnet_tag" {
  for_each = local.eks_subnet_tags

  resource_id = each.value.subnet_id
  key         = "kubernetes.io/cluster/${each.value.cluster_name}"
  value       = "owned"
}

resource "aws_ec2_tag" "eks_internal_elb_subnet_tag" {
  for_each = local.eks_subnet_tags

  resource_id = each.value.subnet_id
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}
