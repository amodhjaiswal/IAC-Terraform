# Aurora Outputs
output "rds_cluster_id" {
  description = "Aurora cluster ID"
  value       = length(aws_rds_cluster.aurora_cluster) > 0 ? aws_rds_cluster.aurora_cluster[0].id : null
}

output "rds_cluster_arn" {
  description = "Aurora cluster ARN"
  value       = length(aws_rds_cluster.aurora_cluster) > 0 ? aws_rds_cluster.aurora_cluster[0].arn : null
}

output "rds_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = length(aws_rds_cluster.aurora_cluster) > 0 ? aws_rds_cluster.aurora_cluster[0].reader_endpoint : null
}

# RDS Instance Outputs
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = length(aws_db_instance.rds_instance) > 0 ? aws_db_instance.rds_instance[0].id : null
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = length(aws_db_instance.rds_instance) > 0 ? aws_db_instance.rds_instance[0].arn : null
}

# Common Outputs
output "rds_endpoint" {
  description = "Database endpoint"
  value = length(aws_rds_cluster.aurora_cluster) > 0 ? aws_rds_cluster.aurora_cluster[0].endpoint : (length(aws_db_instance.rds_instance) > 0 ? aws_db_instance.rds_instance[0].endpoint : null)
}

output "rds_port" {
  description = "Database port"
  value = length(aws_rds_cluster.aurora_cluster) > 0 ? aws_rds_cluster.aurora_cluster[0].port : (length(aws_db_instance.rds_instance) > 0 ? aws_db_instance.rds_instance[0].port : null)
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds_sg.id
}

output "rds_subnet_group_name" {
  description = "RDS subnet group name"
  value       = aws_db_subnet_group.rds_subnet_group.name
}

# Instance/Replica Endpoints
output "rds_instance_endpoints" {
  description = "All database instance endpoints"
  value = length(aws_rds_cluster_instance.aurora_instances) > 0 || length(aws_rds_cluster_instance.aurora_replicas) > 0 ? concat(aws_rds_cluster_instance.aurora_instances[*].endpoint, aws_rds_cluster_instance.aurora_replicas[*].endpoint) : aws_db_instance.rds_replica[*].endpoint
}

output "aurora_primary_endpoints" {
  description = "Aurora primary instance endpoints"
  value = aws_rds_cluster_instance.aurora_instances[*].endpoint
}

output "aurora_replica_endpoints" {
  description = "Aurora replica instance endpoints"
  value = aws_rds_cluster_instance.aurora_replicas[*].endpoint
}

output "engine_type" {
  description = "Database engine type"
  value       = var.engine
}

output "is_aurora" {
  description = "Whether this is an Aurora deployment"
  value       = startswith(var.engine, "aurora")
}
