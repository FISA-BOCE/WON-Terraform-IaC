resource "aws_iam_role" "wg_ha" {
  name = "${var.project_name}-wg-ha-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-wg-ha-role"
  })
}

resource "aws_iam_instance_profile" "wg_ha" {
  name = "${var.project_name}-wg-ha-profile"
  role = aws_iam_role.wg_ha.name
}

resource "aws_iam_role_policy" "wg_ha_route" {
  name = "${var.project_name}-wg-ha-route-policy"
  role = aws_iam_role.wg_ha.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeRouteTables",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstances",
          "ec2:ReplaceRoute"
        ]
        Resource = "*"
      }
    ]
  })
}
