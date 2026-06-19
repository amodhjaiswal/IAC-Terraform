variable "project_name" {
  type = string
}

variable "env_name" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}

variable "aws_account_id" {
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

variable "service_name" {
  type        = string
  description = "Service name for the pipeline"
}

# Global module inputs
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


variable "ecr_repository_url" {
  type        = string
  description = "ecr_repository_url"
}


variable "ecr_repository_name" {
  type        = string
  description = "ecr_repository_name"
}


variable "gitlab_repo_url" {
  type        = string
  description = "GITLAB_URL"
}

variable "gitlab_user_email" {
  type        = string
  description = "GITLAB_USER_EMAIL"
}

variable "gitlab_user" {
  type        = string
  description = "GITLAB_USER"
}

variable "gitlab_pat" {
  type        = string
  description = "GITLAB_PAT"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for notifications"
}

variable "secret_name" {
  type        = string
  description = "Secret manager name"
}

variable "codebuild_region" {
  type        = string
  description = "Region for CodeBuild"
}


variable "new_relic_license_key" {
  type        = string
  description = "New Relic license key"
}




