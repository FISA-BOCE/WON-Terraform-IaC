resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-github-actions-oidc"
  })
}

resource "aws_iam_role" "github_actions_ecr_push" {
  name = "${var.project_name}-github-actions-ecr-push-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for repository in var.github_actions_allowed_repositories :
              "repo:${repository}:*"
            ]
          }
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-github-actions-ecr-push-role"
  })
}

resource "aws_iam_policy" "github_actions_ecr_push" {
  name = "${var.project_name}-github-actions-ecr-push-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = [
          for repository in aws_ecr_repository.channel :
          repository.arn
        ]
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-github-actions-ecr-push-policy"
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr_push" {
  role       = aws_iam_role.github_actions_ecr_push.name
  policy_arn = aws_iam_policy.github_actions_ecr_push.arn
}
