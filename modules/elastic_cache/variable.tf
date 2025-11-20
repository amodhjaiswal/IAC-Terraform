variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "node_type" {
  type        = string
  description = "Redis instance type"
}

variable "engine_version" {
  type        = string
  default     = "7.1"
}

variable "engine_version_major" {
  type        = string
  default     = "7"
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "redis__logs_retention" {
  type        = number
  description = "Redis log retention in days"
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_cluster_mode" {
  description = "Enable cluster mode (true/false)"
  type        = bool
  default     = false
}

variable "num_node_groups" {
  description = "Number of node groups (required when cluster mode = enabled)"
  type        = number
  default     = 2
}

variable "replicas_per_node_group" {
  description = "Replicas per node group when cluster mode enabled"
  type        = number
  default     = 1
}
