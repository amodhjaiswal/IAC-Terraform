variable "project_name" {
  type = string
}

variable "env_name" {
  type = string
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "artifact_bucket_name" {
  type        = string
  description = "Artifact bucket name from global module"
}

variable "codepipeline_role_arn" {
  type        = string
  description = "CodePipeline role ARN from global module"
}

variable "codebuild_role_arn" {
  type        = string
  description = "CodeBuild role ARN from global module"
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID for CloudWatch logs encryption"
}

variable "codebuild_logs_retention" {
  type        = string
  description = "codebuild_logs_retention"
}

variable "bucket_name" {
  type        = string
  description = "bucket_name"
}

variable "cloudfront_distribution_id" {
  type        = string
  description = "cloudfront_distribution_id"
}

variable "frontend_bucket_name" {
  type        = string
  description = "frontend_bucket_name"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for notifications"
}






