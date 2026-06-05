resource "aws_ecr_repository" "channel" {
  for_each = local.ecr_repositories

  name                 = each.value.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.default_tags, {
    Name = each.value.name
    Type = "channel-server"
  })
}

resource "aws_ecr_lifecycle_policy" "channel" {
  for_each = aws_ecr_repository.channel

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
