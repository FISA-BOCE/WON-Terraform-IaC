resource "aws_lb" "dmz" {
  for_each = local.dmz_nlbs

  name               = each.value.name
  internal           = true
  load_balancer_type = "network"
  subnets = [
    data.terraform_remote_state.network.outputs.subnet_ids[each.value.subnet_key]
  ]

  tags = merge(var.default_tags, {
    Name = each.value.name
    Vpc  = each.key
    Role = "dmz-privatelink-nlb"
  })
}

resource "aws_lb" "apigateway" {
  for_each = local.apigateway_nlbs

  name               = each.value.name
  internal           = true
  load_balancer_type = "network"
  subnets = [
    data.terraform_remote_state.network.outputs.subnet_ids[each.value.subnet_key]
  ]

  tags = merge(var.default_tags, {
    Name = each.value.name
    Vpc  = each.key
    Role = "dmz-apigateway-nlb"
  })
}

resource "aws_lb_target_group" "ngnix" {
  for_each = local.dmz_nlbs

  name        = "${each.key}-dmz-ngnix-tg"
  port        = var.ngnix_listener_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_ids[each.key]

  health_check {
    enabled  = true
    port     = "traffic-port"
    protocol = "TCP"
  }

  tags = merge(var.default_tags, {
    Name = "${each.key}-dmz-ngnix-tg"
    Vpc  = each.key
    Role = "dmz-ngnix-target-group"
  })
}

resource "aws_lb_target_group" "apigateway_ngnix" {
  for_each = local.apigateway_nlbs

  name        = "${each.key}-dmz-apigw-ngnix-tg"
  port        = var.ngnix_listener_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_ids[each.key]

  health_check {
    enabled  = true
    port     = "traffic-port"
    protocol = "TCP"
  }

  tags = merge(var.default_tags, {
    Name = "${each.key}-dmz-apigw-ngnix-tg"
    Vpc  = each.key
    Role = "dmz-apigateway-ngnix-target-group"
  })
}

resource "aws_lb_target_group_attachment" "ngnix" {
  for_each = local.dmz_nlbs

  target_group_arn = aws_lb_target_group.ngnix[each.key].arn
  target_id        = data.terraform_remote_state.ngnix.outputs.ngnix_instance_ids[each.value.instance_name]
  port             = var.ngnix_listener_port
}

resource "aws_lb_target_group_attachment" "apigateway_ngnix" {
  for_each = local.apigateway_nlbs

  target_group_arn = aws_lb_target_group.apigateway_ngnix[each.key].arn
  target_id        = data.terraform_remote_state.ngnix.outputs.ngnix_instance_ids[each.value.instance_name]
  port             = var.ngnix_listener_port
}

resource "aws_lb_listener" "ngnix" {
  for_each = local.dmz_nlbs

  load_balancer_arn = aws_lb.dmz[each.key].arn
  port              = var.ngnix_listener_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ngnix[each.key].arn
  }

  tags = merge(var.default_tags, {
    Name = "${each.key}-dmz-ngnix-listener"
    Vpc  = each.key
  })
}

resource "aws_lb_listener" "apigateway_ngnix" {
  for_each = local.apigateway_nlbs

  load_balancer_arn = aws_lb.apigateway[each.key].arn
  port              = var.ngnix_listener_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apigateway_ngnix[each.key].arn
  }

  tags = merge(var.default_tags, {
    Name = "${each.key}-dmz-apigateway-ngnix-listener"
    Vpc  = each.key
  })
}
