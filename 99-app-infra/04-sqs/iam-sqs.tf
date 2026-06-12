data "aws_iam_policy_document" "card_channel_sqs_access" {
  count = var.enable_sqs ? 1 : 0

  statement {
    sid    = "AllowPublishSweepRequests"
    effect = "Allow"

    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.sweep["sweep_request"].arn
    ]
  }

  statement {
    sid    = "AllowConsumeSweepResults"
    effect = "Allow"

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage"
    ]

    resources = [
      aws_sqs_queue.sweep["sweep_result"].arn
    ]
  }
}

data "aws_iam_policy_document" "invest_channel_sqs_access" {
  count = var.enable_sqs ? 1 : 0

  statement {
    sid    = "AllowConsumeSweepRequests"
    effect = "Allow"

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage"
    ]

    resources = [
      aws_sqs_queue.sweep["sweep_request"].arn
    ]
  }

  statement {
    sid    = "AllowPublishSweepResults"
    effect = "Allow"

    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.sweep["sweep_result"].arn
    ]
  }
}

resource "aws_iam_policy" "card_channel_sqs_access" {
  count = var.enable_sqs ? 1 : 0

  name        = "${var.project}-${var.env}-card-channel-sqs-access-policy"
  description = "Allow Card Channel to publish sweep requests and consume sweep results"
  policy      = data.aws_iam_policy_document.card_channel_sqs_access[0].json

  tags = merge(var.default_tags, {
    Name        = "${var.project}-${var.env}-card-channel-sqs-access-policy"
    Environment = var.env
    Service     = "card-channel"
  })
}

resource "aws_iam_policy" "invest_channel_sqs_access" {
  count = var.enable_sqs ? 1 : 0

  name        = "${var.project}-${var.env}-invest-channel-sqs-access-policy"
  description = "Allow Invest Channel to consume sweep requests and publish sweep results"
  policy      = data.aws_iam_policy_document.invest_channel_sqs_access[0].json

  tags = merge(var.default_tags, {
    Name        = "${var.project}-${var.env}-invest-channel-sqs-access-policy"
    Environment = var.env
    Service     = "invest-channel"
  })
}

resource "aws_iam_role_policy_attachment" "card_channel_sqs_access" {
  for_each = var.enable_sqs && contains(keys(var.eks_node_role_names), "card") ? {
    card = var.eks_node_role_names["card"]
  } : {}

  role       = each.value
  policy_arn = aws_iam_policy.card_channel_sqs_access[0].arn
}

resource "aws_iam_role_policy_attachment" "invest_channel_sqs_access" {
  for_each = var.enable_sqs && contains(keys(var.eks_node_role_names), "securities") ? {
    securities = var.eks_node_role_names["securities"]
  } : {}

  role       = each.value
  policy_arn = aws_iam_policy.invest_channel_sqs_access[0].arn
}
