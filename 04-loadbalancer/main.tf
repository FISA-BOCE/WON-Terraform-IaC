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
    Role = "dmz-nlb"
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

resource "aws_lb_target_group_attachment" "ngnix" {
  for_each = local.dmz_nlbs

  target_group_arn = aws_lb_target_group.ngnix[each.key].arn
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
