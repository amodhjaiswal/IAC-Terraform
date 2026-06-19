output "web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_name" {
  description = "Name of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.name
}

output "whitelist_ip_set_arn" {
  description = "ARN of the whitelist IP set"
  value       = aws_wafv2_ip_set.whitelist.arn
}

output "blacklist_ip_set_arn" {
  description = "ARN of the blacklist IP set"
  value       = aws_wafv2_ip_set.blacklist.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for WAF logs"
  value       = aws_cloudwatch_log_group.waf_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for WAF logs"
  value       = aws_cloudwatch_log_group.waf_logs.arn
}
