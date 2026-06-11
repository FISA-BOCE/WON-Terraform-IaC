resource "aws_vpc_endpoint_service" "this" {
  for_each = local.endpoint_services

  acceptance_required        = false
  network_load_balancer_arns = [data.terraform_remote_state.loadbalancer.outputs.dmz_privatelink_nlb_arns[each.key]]

  tags = merge(var.default_tags, {
    Name = "${each.value.name}-endpoint-service"
    Vpc  = each.value.vpc_key
    Role = "private-link-endpoint-service"
  })
}

resource "aws_vpc_endpoint_service_allowed_principal" "current_account" {
  for_each = aws_vpc_endpoint_service.this

  vpc_endpoint_service_id = each.value.id
  principal_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}

resource "aws_security_group" "endpoint" {
  for_each = local.private_link_endpoints

  name        = "${each.value.name}-sg"
  description = "Allow clients in ${each.value.vpc_key} VPC to use PrivateLink endpoint"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_ids[each.value.vpc_key]

  ingress {
    description = "Allow all inbound traffic to the PrivateLink endpoint ENI"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow endpoint ENI responses"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, {
    Name = "${each.value.name}-sg"
    Vpc  = each.value.vpc_key
    Role = "private-link-endpoint"
  })
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.private_link_endpoints

  vpc_id              = data.terraform_remote_state.network.outputs.vpc_ids[each.value.vpc_key]
  service_name        = aws_vpc_endpoint_service.this[each.value.service_key].service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [data.terraform_remote_state.network.outputs.subnet_ids[each.value.subnet_key]]
  security_group_ids  = [aws_security_group.endpoint[each.key].id]
  private_dns_enabled = false

  tags = merge(var.default_tags, {
    Name        = each.value.name
    Vpc         = each.value.vpc_key
    ServiceVpc  = local.endpoint_services[each.value.service_key].vpc_key
    ServiceName = local.endpoint_services[each.value.service_key].name
    Role        = "private-link-endpoint"
  })

  lifecycle {
    precondition {
      condition     = data.aws_subnet.endpoint[each.key].availability_zone == data.aws_subnet.service[each.value.service_key].availability_zone
      error_message = "PrivateLink endpoint subnet must be in the same Availability Zone as the service NLB subnet."
    }
  }

  depends_on = [
    aws_vpc_endpoint_service_allowed_principal.current_account
  ]
}

resource "aws_route53_zone" "private_link" {
  for_each = local.vpcs

  name = "internal"

  vpc {
    vpc_id = data.terraform_remote_state.network.outputs.vpc_ids[each.key]
  }

  tags = merge(var.default_tags, {
    Name = "${each.key}-internal-zone"
    Vpc  = each.key
    Role = "private-link-dns"
  })
}

resource "aws_route53_record" "private_link" {
  for_each = local.private_link_dns_records

  zone_id = aws_route53_zone.private_link[each.value.zone_vpc_key].zone_id
  name    = each.value.name
  type    = "A"

  alias {
    name                   = aws_vpc_endpoint.this[each.value.endpoint_key].dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.this[each.value.endpoint_key].dns_entry[0].hosted_zone_id
    evaluate_target_health = false
  }
}
