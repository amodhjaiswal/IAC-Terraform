variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "resource_name" {
  description = "Resource name for SNS topic"
  type        = string
}

variable "emails" {
  description = "List of email addresses for subscription"
  type        = list(string)
}
