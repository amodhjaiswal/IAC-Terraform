# variable "ecr_repository_url" {
#   type        = string
#   description = "ecr_repository_url"
# }

# variable "ecr_repository_name" {
#   type        = string
#   description = "ecr_repository_name"
# }

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

variable "codebuild_logs_retention" {
  type        = string
  description = "codebuild_logs_retention"
}

variable "new_relic_license_key" {
  type        = string
  description = "New Relic license key"
}

# variable "codebuild_region" {
#   type        = string
#   description = "Region for CodeBuild"
# }
