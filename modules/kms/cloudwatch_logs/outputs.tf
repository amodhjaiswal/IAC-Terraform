output "kms_key_id" {
  description = "KMS key ID for CloudWatch logs encryption"
  value       = aws_kms_key.cloudwatch_logs.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for CloudWatch logs encryption"
  value       = aws_kms_key.cloudwatch_logs.arn
}

output "kms_alias_name" {
  description = "KMS key alias name"
  value       = aws_kms_alias.cloudwatch_logs.name
}
