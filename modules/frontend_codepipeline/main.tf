#############################################
# Locals
#############################################
locals {
  name_prefix = "${var.project_name}-${var.env_name}"
  tags = merge(
    {
      Name        = local.name_prefix
      Project     = var.project_name
      Environment = var.env_name
    },
    var.tags
  )
}

#############################################
# CodePipeline
#############################################
resource "aws_codepipeline" "this" {
  name     = "${local.name_prefix}-${var.frontend_bucket_name}-frontend"
  role_arn = var.codepipeline_role_arn

     lifecycle {
    ignore_changes = [stage]
  }

  artifact_store {
    location = var.artifact_bucket_name
    type     = "S3"
  }

  # Source Stage (hardcoded sample values)
  stage {
    name = "Source"
    action {
      name            = "Source"
      category        = "Source"
      owner           = "AWS"
      provider        = "CodeCommit"
      version         = "1"
      output_artifacts = ["source_output"]
      configuration = {
        RepositoryName = "example-repo"
        BranchName     = "main"
      }
    }
  }

  # Build Stage
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = "${local.name_prefix}-${var.frontend_bucket_name}-frontend-codebuild"
      }
    }
  }

  tags = local.tags
}
#############################################
# Random delay for notification rule creation
#############################################
resource "random_integer" "delay" {
  min = 10
  max = 60
}

resource "time_sleep" "notification_delay" {
  depends_on = [aws_codepipeline.this]
  create_duration = "${random_integer.delay.result}s"
}

#############################################
# CodePipeline Notifications
#############################################
resource "aws_codestarnotifications_notification_rule" "pipeline_notifications" {
  detail_type = "FULL"
  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded"
  ]
  name     = "${local.name_prefix}-${var.frontend_bucket_name}-frontend-notifications"
  resource = aws_codepipeline.this.arn

  target {
    address = var.sns_topic_arn
    type    = "SNS"
  }

  tags = local.tags

  depends_on = [time_sleep.notification_delay]

  lifecycle {
    create_before_destroy = true
  }
}

#############################################
# CloudWatch Logs for CodeBuild only
#############################################
resource "aws_cloudwatch_log_group" "codebuild_logs" {
  name              = "/aws/codebuild/${local.name_prefix}-${var.frontend_bucket_name}-frontend-codebuild"
  retention_in_days = var.codebuild_logs_retention
  kms_key_id        = var.kms_key_id
  tags              = local.tags
}

