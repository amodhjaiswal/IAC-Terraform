variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "engine" {
  description = "Database engine (mysql, postgres, aurora-mysql, aurora-postgresql)"
  type        = string
  validation {
    condition = contains([
      "mysql", "postgres", "aurora-mysql", "aurora-postgresql"
    ], var.engine)
    error_message = "Engine must be one of: mysql, postgres, aurora-mysql, aurora-postgresql."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
}

variable "engine_version_major" {
  description = "Major version for parameter group family"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "instance_count" {
  description = "Number of instances (Aurora only)"
  type        = number
  default     = 1
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB (RDS only)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling (RDS only)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (RDS only)"
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment (RDS only)"
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 0
}

variable "replica_instance_class" {
  description = "Instance class for read replicas"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch (auto-detected if empty)"
  type        = list(string)
  default     = []
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  type        = number
  default     = 60
}

variable "rds_logs_retention" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 365
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "db_parameters" {
  description = "Database parameters for parameter group"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
}
