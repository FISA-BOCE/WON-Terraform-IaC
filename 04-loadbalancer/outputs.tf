output "dmz_nlb_arns" {
  description = "DMZ NLB ARNs by VPC key"
  value = {
    for key, lb in aws_lb.dmz : key => lb.arn
  }
}

output "dmz_nlb_dns_names" {
  description = "DMZ NLB DNS names by VPC key"
  value = {
    for key, lb in aws_lb.dmz : key => lb.dns_name
  }
}

output "dmz_nlb_zone_ids" {
  description = "DMZ NLB Route53 zone IDs by VPC key"
  value = {
    for key, lb in aws_lb.dmz : key => lb.zone_id
  }
}

output "dmz_ngnix_target_group_arns" {
  description = "DMZ Nginx target group ARNs by VPC key"
  value = {
    for key, target_group in aws_lb_target_group.ngnix : key => target_group.arn
  }
}

output "dmz_ngnix_listener_arns" {
  description = "DMZ Nginx listener ARNs by VPC key"
  value = {
    for key, listener in aws_lb_listener.ngnix : key => listener.arn
  }
}
