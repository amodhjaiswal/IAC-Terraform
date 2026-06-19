output "alb_logs_bucket_name" {
  description = "Name of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_access_logs.bucket
}

output "alb_logs_bucket_arn" {
  description = "ARN of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_access_logs.arn
}

output "alb_logs_bucket_id" {
  description = "ID of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_access_logs.id
}
