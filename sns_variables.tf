variable "sns_backend_name" {
  description = "Resource name for SNS topic"
  type        = string
}

variable "sns_backend_emails" {
  description = "List of email addresses for SNS subscription"
  type        = list(string)
}


variable "sns_frontend_name" {
  description = "Resource name for SNS topic"
  type        = string
}

variable "sns_frontend_emails" {
  description = "List of email addresses for SNS subscription"
  type        = list(string)
}
