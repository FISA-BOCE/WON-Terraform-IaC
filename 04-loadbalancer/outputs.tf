output "dmz_privatelink_nlb_arns" {
  description = "DMZ PrivateLink NLB ARNs by VPC key"
  value = {
    for key, lb in aws_lb.dmz : key => lb.arn
  }
}

output "dmz_privatelink_nlb_dns_names" {
  description = "DMZ PrivateLink NLB DNS names by VPC key"
  value = {
    for key, lb in aws_lb.dmz : key => lb.dns_name
  }
}

output "dmz_privatelink_nlb_zone_ids" {
  description = "DMZ PrivateLink NLB Route53 zone IDs by VPC key"
  value = {
    for key, lb in aws_lb.dmz : key => lb.zone_id
  }
}

output "dmz_apigateway_nlb_arns" {
  description = "DMZ API Gateway NLB ARNs by VPC key"
  value = {
    for key, lb in aws_lb.apigateway : key => lb.arn
  }
}

output "dmz_apigateway_nlb_dns_names" {
  description = "DMZ API Gateway NLB DNS names by VPC key"
  value = {
    for key, lb in aws_lb.apigateway : key => lb.dns_name
  }
}

output "dmz_apigateway_nlb_zone_ids" {
  description = "DMZ API Gateway NLB Route53 zone IDs by VPC key"
  value = {
    for key, lb in aws_lb.apigateway : key => lb.zone_id
  }
}

output "dmz_ngnix_target_group_arns" {
  description = "DMZ PrivateLink Nginx target group ARNs by VPC key"
  value = {
    for key, target_group in aws_lb_target_group.ngnix : key => target_group.arn
  }
}

output "dmz_apigateway_ngnix_target_group_arns" {
  description = "DMZ API Gateway Nginx target group ARNs by VPC key"
  value = {
    for key, target_group in aws_lb_target_group.apigateway_ngnix : key => target_group.arn
  }
}

output "dmz_ngnix_listener_arns" {
  description = "DMZ PrivateLink Nginx listener ARNs by VPC key"
  value = {
    for key, listener in aws_lb_listener.ngnix : key => listener.arn
  }
}

output "dmz_apigateway_ngnix_listener_arns" {
  description = "DMZ API Gateway Nginx listener ARNs by VPC key"
  value = {
    for key, listener in aws_lb_listener.apigateway_ngnix : key => listener.arn
  }
}
