variable "region" {
  description = "Primary region for most resources"
  type        = string
}

variable "pipeline_region" {
  description = "Region for CodePipeline resources"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "env_name" {
  description = "Environment name (workspace)"
  type        = string
}

variable "aws_account_id" {
  description = "aws_account_id"
  type = string
}

variable "domain" {
  description = "Domain name for ingress hosts"
  type        = string
}

variable "certificate_arn" {
  description = "certificate arn"
  type        = string
}

variable "front_end_certificate_arn" {
  description = "front_end_certificate_arn"
  type        = string
}

variable "skip_eks_namespace_on_error" {
  description = "Skip EKS namespace creation if errors occur during apply/destroy"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "waf_logs_retention" {
  description = "waf__logs_retention"
  type        = string
}

