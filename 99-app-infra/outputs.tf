# =========================================================
# RDS Outputs
# =========================================================

output "rds_endpoint" {
  description = "RDS MySQL endpoint with port"
  value = {
    for key, db in aws_db_instance.mysql :
    key => db.endpoint
  }

}

output "rds_addresses" {
  description = "RDS MySQL addresses by network"
  value = {
    for key, db in aws_db_instance.mysql :
    key => db.address
  }
}

output "rds_security_group_ids" {
  description = "RDS Security Group IDs by network"
  value = {
    for key, sg in aws_security_group.rds_mysql :
    key => sg.id
  }
}

output "app_security_group_ids" {
  description = "Application Security Group IDs allowed to access RDS and Redis by network"
  value = {
    for key, sg in aws_security_group.app :
    key => sg.id
  }
}
