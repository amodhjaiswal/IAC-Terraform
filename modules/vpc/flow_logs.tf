# Generating a random 4-digit number for unique S3 bucket name
resource "random_integer" "flow_logs_bucket_suffix" {
  min = 1000
  max = 9999
}

# S3 bucket for VPC flow logs
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket        = "${var.project_name}-${var.env_name}-vpc-flow-logs-${random_integer.flow_logs_bucket_suffix.result}"
  force_destroy = true
}

# Disabling ACL for the S3 bucket
resource "aws_s3_bucket_ownership_controls" "flow_logs_ownership" {
  bucket = aws_s3_bucket.vpc_flow_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Enabling versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "flow_logs_versioning" {
  bucket = aws_s3_bucket.vpc_flow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enabling server-side encryption with SSE-S3
resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs_encryption" {
  bucket = aws_s3_bucket.vpc_flow_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "flow_logs_pab" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Adding lifecycle rule to manage flow log retention
resource "aws_s3_bucket_lifecycle_configuration" "flow_logs_lifecycle" {
  bucket = aws_s3_bucket.vpc_flow_logs.id
  rule {
    id     = "flow-logs-retention"
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

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  log_destination      = aws_s3_bucket.vpc_flow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main_vpc.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env_name}-vpc-flow-logs"
  })
}

# # VPC Flow Logs
# resource "aws_flow_log" "vpc_flow_logs" {
#   iam_role_arn    = aws_iam_role.vpc_flow_logs_role.arn
#   log_destination = aws_s3_bucket.vpc_flow_logs.arn
#   traffic_type    = "ALL"
#   vpc_id          = aws_vpc.main_vpc.id

#   tags = merge(var.tags, {
#     Name = "${var.project_name}-${var.env_name}-vpc-flow-logs"
#   })
# }
