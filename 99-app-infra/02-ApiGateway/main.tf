resource "aws_api_gateway_rest_api" "mobile" {
  name        = var.api_name
  description = "Mobile app entrypoint REST API Gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(var.default_tags, {
    Name = var.api_name
    Role = "mobile-api-entrypoint"
  })
}

resource "aws_api_gateway_vpc_link" "backend" {
  for_each = local.backend_routes

  name        = each.value.vpc_link_name
  description = "REST API Gateway VPC Link for ${each.key} DMZ NLB"
  target_arns = [
    each.value.nlb_arn
  ]

  tags = merge(var.default_tags, {
    Name = each.value.vpc_link_name
    Vpc  = each.value.vpc_link_key
  })
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.mobile.id
  parent_id   = aws_api_gateway_rest_api.mobile.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "service" {
  for_each = local.backend_routes

  rest_api_id = aws_api_gateway_rest_api.mobile.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "service_proxy" {
  for_each = local.backend_routes

  rest_api_id = aws_api_gateway_rest_api.mobile.id
  parent_id   = aws_api_gateway_resource.service[each.key].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "service_any" {
  for_each = local.backend_routes

  rest_api_id   = aws_api_gateway_rest_api.mobile.id
  resource_id   = aws_api_gateway_resource.service[each.key].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "service_proxy_any" {
  for_each = local.backend_routes

  rest_api_id   = aws_api_gateway_rest_api.mobile.id
  resource_id   = aws_api_gateway_resource.service_proxy[each.key].id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "service_any" {
  for_each = local.backend_routes

  rest_api_id             = aws_api_gateway_rest_api.mobile.id
  resource_id             = aws_api_gateway_resource.service[each.key].id
  http_method             = aws_api_gateway_method.service_any[each.key].http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.backend[each.key].id
  uri                     = "http://${each.value.nlb_dns_name}:${var.ngnix_listener_port}/${each.value.backend_path}"
}

resource "aws_api_gateway_integration" "service_proxy_any" {
  for_each = local.backend_routes

  rest_api_id             = aws_api_gateway_rest_api.mobile.id
  resource_id             = aws_api_gateway_resource.service_proxy[each.key].id
  http_method             = aws_api_gateway_method.service_proxy_any[each.key].http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.backend[each.key].id
  uri                     = "http://${each.value.nlb_dns_name}:${var.ngnix_listener_port}/${each.value.backend_path}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "mobile" {
  rest_api_id = aws_api_gateway_rest_api.mobile.id

  triggers = {
    redeployment = sha1(jsonencode({
      resources = concat(
        [aws_api_gateway_resource.api.id],
        [for resource in aws_api_gateway_resource.service : resource.id],
        [for resource in aws_api_gateway_resource.service_proxy : resource.id]
      )
      methods = concat(
        [for method in aws_api_gateway_method.service_any : method.id],
        [for method in aws_api_gateway_method.service_proxy_any : method.id]
      )
      integrations = concat(
        [for integration in aws_api_gateway_integration.service_any : integration.id],
        [for integration in aws_api_gateway_integration.service_proxy_any : integration.id]
      )
    }))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.service_any,
    aws_api_gateway_integration.service_proxy_any
  ]
}

resource "aws_api_gateway_stage" "mobile" {
  rest_api_id   = aws_api_gateway_rest_api.mobile.id
  deployment_id = aws_api_gateway_deployment.mobile.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      caller           = "$context.identity.caller"
      user             = "$context.identity.user"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      resourcePath     = "$context.resourcePath"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  tags = merge(var.default_tags, {
    Name = "${var.api_name}-${var.stage_name}"
  })

  depends_on = [
    aws_api_gateway_account.this
  ]
}

resource "aws_wafv2_web_acl" "mobile_api" {
  name        = "${var.api_name}-waf"
  description = "WAF for BOCE mobile REST API Gateway"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BOCEApiGatewayCommonRules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BOCEApiGatewayKnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "BOCEApiGatewayWAF"
    sampled_requests_enabled   = true
  }

  tags = merge(var.default_tags, {
    Name = "${var.api_name}-waf"
  })
}

resource "aws_wafv2_web_acl_association" "mobile_api" {
  resource_arn = "arn:aws:apigateway:${data.aws_region.current.region}::/restapis/${aws_api_gateway_rest_api.mobile.id}/stages/${aws_api_gateway_stage.mobile.stage_name}"
  web_acl_arn  = aws_wafv2_web_acl.mobile_api.arn

  depends_on = [
    aws_api_gateway_stage.mobile
  ]
}
