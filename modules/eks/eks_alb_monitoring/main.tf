# Generating a random 4-digit number for unique S3 bucket name
resource "random_integer" "alb_logs_bucket_suffix" {
  min = 1000
  max = 9999
}

# S3 bucket for ALB access logs
resource "aws_s3_bucket" "alb_access_logs" {
  bucket        = "${var.project_name}-${var.env_name}-alb-logs-${random_integer.alb_logs_bucket_suffix.result}"
  force_destroy = true
}

# Disabling ACL for the S3 bucket
resource "aws_s3_bucket_ownership_controls" "alb_logs_ownership" {
  bucket = aws_s3_bucket.alb_access_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Enabling versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "alb_logs_versioning" {
  bucket = aws_s3_bucket.alb_access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enabling server-side encryption with SSE-S3
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs_encryption" {
  bucket = aws_s3_bucket.alb_access_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "alb_logs_pab" {
  bucket = aws_s3_bucket.alb_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Adding lifecycle rule to manage ALB log retention
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs_lifecycle" {
  bucket = aws_s3_bucket.alb_access_logs.id
  rule {
    id     = "alb-logs-retention"
    status = "Enabled"
    filter {
      prefix = ""
    }
    expiration {
      days = 30
    }
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# S3 bucket policy for ALB access logs
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_access_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_access_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_access_logs.arn
      }
    ]
  })
}

# Data source for ELB service account
data "aws_elb_service_account" "main" {}
