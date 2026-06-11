output "endpoint_service_ids" {
  description = "PrivateLink endpoint service IDs by service key"
  value = {
    for key, service in aws_vpc_endpoint_service.this : key => service.id
  }
}

output "endpoint_service_names" {
  description = "PrivateLink endpoint service names by service key"
  value = {
    for key, service in aws_vpc_endpoint_service.this : key => service.service_name
  }
}

output "endpoint_ids" {
  description = "Interface VPC endpoint IDs by endpoint key"
  value = {
    for key, endpoint in aws_vpc_endpoint.this : key => endpoint.id
  }
}

output "endpoint_dns_entries" {
  description = "Interface VPC endpoint DNS entries by endpoint key"
  value = {
    for key, endpoint in aws_vpc_endpoint.this : key => endpoint.dns_entry
  }
}

output "endpoint_security_group_ids" {
  description = "PrivateLink endpoint security group IDs by endpoint key"
  value = {
    for key, sg in aws_security_group.endpoint : key => sg.id
  }
}
