###########----------RDS---------###########

variable "rds_engine" {
  description = "Database engine (mysql, postgres, aurora-mysql, aurora-postgresql)"
  type        = string
  validation {
    condition = contains([
      "mysql", "postgres", "aurora-mysql", "aurora-postgresql"
    ], var.rds_engine)
    error_message = "Engine must be one of: mysql, postgres, aurora-mysql, aurora-postgresql."
  }
}

variable "rds_engine_version" {
  description = "Database engine version"
  type        = string
}

variable "rds_engine_version_major" {
  description = "Major version for parameter group family "
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_instance_count" {
  description = "Number of instances (Aurora only)"
  type        = number
  default     = 1
}

variable "rds_allocated_storage" {
  description = "Initial allocated storage in GB (RDS only)"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling (RDS only)"
  type        = number
  default     = 100
}

variable "rds_db_name" {
  description = "Database name"
  type        = string
}

variable "rds_master_username" {
  description = "Master username for the database"
  type        = string
}

variable "rds_master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment (RDS only)"
  type        = bool
  default     = false
}

variable "rds_replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 0
}

variable "rds_replica_instance_class" {
  description = "Instance class for read replicas"
  type        = string
  default     = null
}

variable "rds_logs_retention" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 365
}

variable "rds_db_parameters" {
  description = "Database parameters for parameter group"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
