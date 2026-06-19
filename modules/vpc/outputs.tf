output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_id" {
  description = "First NAT Gateway ID (for backward compatibility)"
  value       = aws_nat_gateway.this[0].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "private_route_table_id" {
  description = "First private route table ID (for backward compatibility)"
  value       = aws_route_table.private[0].id
}

output "vpc_flow_logs_bucket_name" {
  description = "VPC Flow Logs S3 bucket name"
  value       = aws_s3_bucket.vpc_flow_logs.bucket
}

output "vpc_flow_logs_bucket_arn" {
  description = "VPC Flow Logs S3 bucket ARN"
  value       = aws_s3_bucket.vpc_flow_logs.arn
}
