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

variable "allowlist_ips" {
  description = "List of IP addresses to allowlist"
  type        = list(string)
  default     = []
}

variable "blocklist_ips" {
  description = "List of IP addresses to blocklist"
  type        = list(string)
  default     = []
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting CloudWatch logs"
  type        = string
}

variable "waf_logs_retention" {
  description = "WAF logs retention in days"
  type        = number
  default     = 30
}
