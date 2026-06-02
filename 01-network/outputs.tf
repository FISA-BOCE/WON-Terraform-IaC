output "vpc_ids" {
  description = "VPC IDs by logical key"
  value = {
    for key, vpc in aws_vpc.this : key => vpc.id
  }
}

output "vpc_cidrs" {
  description = "VPC CIDR blocks by logical key"
  value = {
    for key, vpc in aws_vpc.this : key => vpc.cidr_block
  }
}

output "subnet_ids" {
  description = "Subnet IDs by subnet name"
  value = {
    for key, subnet in aws_subnet.this : key => subnet.id
  }
}

output "public_route_table_ids" {
  description = "Public route table IDs by VPC key"
  value = {
    for key, route_table in aws_route_table.public : key => route_table.id
  }
}

output "private_route_table_ids" {
  description = "Private route table IDs by VPC key"
  value = {
    for key, route_table in aws_route_table.private : key => route_table.id
  }
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs by VPC key"
  value = {
    for key, nat_gateway in aws_nat_gateway.this : key => nat_gateway.id
  }
}

output "boce_key_pair_name" {
  description = "AWS key pair name for EC2 instances"
  value       = aws_key_pair.boce_key.key_name
}

output "boce_private_key_file" {
  description = "Generated private key PEM file path"
  value       = local_file.boce_private_key.filename
}

output "boce_public_key" {
  description = "Generated public key in OpenSSH format"
  value       = tls_private_key.boce_key.public_key_openssh
}
