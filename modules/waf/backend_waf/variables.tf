variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "env_name" {
  description = "Environment name (e.g., dev, prod) for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "scope" {
  description = "Scope of the WAF (CLOUDFRONT or REGIONAL)"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "Scope must be either CLOUDFRONT or REGIONAL."
  }
}

variable "rate_limit" {
  description = "Rate limit for requests per 5-minute period"
  type        = number
  default     = 2000
}

variable "blocked_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = ["CN", "RU", "KP", "IR"]
}

variable "whitelist_ips" {
  description = "List of IP addresses to whitelist"
  type        = list(string)
  default     = []
}

variable "blacklist_ips" {
  description = "List of IP addresses to blacklist ips"
  type        = list(string)
  default     = []
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting CloudWatch logs"
  type        = string
}

variable "waf_logs_retention" {
  description = "waf__logs_retention"
  type        = string
}


