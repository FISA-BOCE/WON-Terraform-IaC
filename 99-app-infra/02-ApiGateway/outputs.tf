output "rest_api_id" {
  description = "REST API Gateway ID"
  value       = aws_api_gateway_rest_api.mobile.id
}

output "rest_api_execution_arn" {
  description = "REST API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.mobile.execution_arn
}

output "rest_api_invoke_url" {
  description = "REST API Gateway invoke URL"
  value       = aws_api_gateway_stage.mobile.invoke_url
}

output "vpc_link_ids" {
  description = "REST API Gateway VPC Link IDs by backend route"
  value = {
    for key, vpc_link in aws_api_gateway_vpc_link.backend : key => vpc_link.id
  }
}

output "vpc_link_names" {
  description = "REST API Gateway VPC Link names by backend route"
  value = {
    for key, vpc_link in aws_api_gateway_vpc_link.backend : key => vpc_link.name
  }
}

output "waf_web_acl_arn" {
  description = "WAFv2 Web ACL ARN associated with the REST API stage"
  value       = aws_wafv2_web_acl.mobile_api.arn
}

output "api_gateway_access_log_group_name" {
  description = "CloudWatch Log Group name for API Gateway access logs"
  value       = aws_cloudwatch_log_group.api_gateway_access.name
}

output "api_gateway_cloudwatch_role_arn" {
  description = "IAM role ARN used by API Gateway to write CloudWatch execution logs"
  value       = aws_iam_role.api_gateway_cloudwatch.arn
}
