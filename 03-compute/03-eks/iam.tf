resource "aws_iam_role" "eks_cluster" {
  for_each = local.eks_clusters

  name = "${each.value.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${each.value.cluster_name}-cluster-role"
    Vpc  = each.value.vpc_key
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  for_each = local.eks_clusters

  role       = aws_iam_role.eks_cluster[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node" {
  for_each = local.eks_clusters

  name = "${each.value.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${each.value.cluster_name}-node-role"
    Vpc  = each.value.vpc_key
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  for_each = local.eks_clusters

  role       = aws_iam_role.eks_node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  for_each = local.eks_clusters

  role       = aws_iam_role.eks_node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  for_each = local.eks_clusters

  role       = aws_iam_role.eks_node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
