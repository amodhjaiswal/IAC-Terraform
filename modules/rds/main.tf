locals {
  is_aurora = startswith(var.engine, "aurora")
  is_mysql = contains(["mysql", "aurora-mysql"], var.engine)
  is_postgres = contains(["postgres", "aurora-postgresql"], var.engine)
  
  port = local.is_mysql ? 3306 : 5432
  
  parameter_group_family = local.is_aurora ? (
    local.is_mysql ? "aurora-mysql${var.engine_version_major}" : "aurora-postgresql${var.engine_version_major}"
  ) : (
    local.is_mysql ? "mysql${var.engine_version_major}" : "postgres${var.engine_version_major}"
  )
  
  log_types = local.is_mysql ? (
    local.is_aurora ? ["audit", "error", "general", "slowquery"] : ["error", "general", "slow-query"]
  ) : ["postgresql"]
  
  final_log_types = length(var.enabled_cloudwatch_logs_exports) > 0 ? var.enabled_cloudwatch_logs_exports : local.log_types
  replica_instance_class = var.replica_instance_class != null ? var.replica_instance_class : var.instance_class
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-${var.env_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env_name}-rds-subnet-group"
  })
}

# Security Group
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-${var.env_name}-rds-sg"
  description = "Security group for RDS ${local.is_aurora ? "Aurora cluster" : "instance"}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = local.port
    to_port     = local.port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "${local.is_mysql ? "MySQL" : "PostgreSQL"} access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env_name}-rds-sg"
  })
}

# Enhanced Monitoring Role
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.project_name}-${var.env_name}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Parameter Groups - RDS
resource "aws_db_parameter_group" "rds_parameter_group" {
  count = local.is_aurora ? 0 : 1
  
  family = local.parameter_group_family
  name   = "${var.project_name}-${var.env_name}-rds-params"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Parameter Groups - Aurora
resource "aws_rds_cluster_parameter_group" "aurora_parameter_group" {
  count = local.is_aurora ? 1 : 0
  
  family = local.parameter_group_family
  name   = "${var.project_name}-${var.env_name}-aurora-params"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Aurora Cluster
resource "aws_rds_cluster" "aurora_cluster" {
  count = local.is_aurora ? 1 : 0
  
  cluster_identifier = "${var.project_name}-${var.env_name}-aurora"

  engine         = var.engine
  engine_version = var.engine_version
  engine_mode    = "provisioned"

  database_name   = var.db_name
  master_username = var.master_username
  master_password = var.master_password

  vpc_security_group_ids          = [aws_security_group.rds_sg.id]
  db_subnet_group_name           = aws_db_subnet_group.rds_subnet_group.name
  db_cluster_parameter_group_name = local.is_aurora && length(var.db_parameters) > 0 ? aws_rds_cluster_parameter_group.aurora_parameter_group[0].name : null

  storage_encrypted = true
  kms_key_id       = var.kms_key_id

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  enabled_cloudwatch_logs_exports = local.final_log_types

  deletion_protection       = var.deletion_protection
  skip_final_snapshot      = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.env_name}-aurora-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env_name}-aurora"
  })

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}

# Aurora Primary Instances
resource "aws_rds_cluster_instance" "aurora_instances" {
  count = local.is_aurora ? var.instance_count : 0

  identifier         = "${var.project_name}-${var.env_name}-aurora-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora_cluster[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.aurora_cluster[0].engine
  engine_version     = aws_rds_cluster.aurora_cluster[0].engine_version
  availability_zone  = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  apply_immediately  = true

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_id : null

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env_name}-aurora-${count.index + 1}"
  })
}

# Aurora Read Replicas (Secondary Instances)
resource "aws_rds_cluster_instance" "aurora_replicas" {
  count = local.is_aurora ? var.replica_count : 0

  identifier         = "${var.project_name}-${var.env_name}-aurora-replica-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora_cluster[0].id
  instance_class     = local.replica_instance_class
  engine             = aws_rds_cluster.aurora_cluster[0].engine
  engine_version     = aws_rds_cluster.aurora_cluster[0].engine_version
  availability_zone  = data.aws_availability_zones.available.names[(count.index + var.instance_count) % length(data.aws_availability_zones.available.names)]
  apply_immediately  = true

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_id : null

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env_name}-aurora-replica-${count.index + 1}"
  })
}

# RDS Instance
resource "aws_db_instance" "rds_instance" {
  count = local.is_aurora ? 0 : 1
  
  identifier = "${var.project_name}-${var.env_name}-rds"

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id           = var.kms_key_id

  db_name  = var.db_name
  username = var.master_username
  password = var.master_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  parameter_group_name   = !local.is_aurora && length(var.db_parameters) > 0 ? aws_db_parameter_group.rds_parameter_group[0].name : null

  multi_az               = var.multi_az
  publicly_accessible    = false
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  enabled_cloudwatch_logs_exports = local.final_log_types
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn            = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_id : null

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.env_name}-rds-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env_name}-rds"
  })

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}

# Read Replicas
resource "aws_db_instance" "rds_replica" {
  count = local.is_aurora ? 0 : var.replica_count

  identifier = "${var.project_name}-${var.env_name}-rds-replica-${count.index + 1}"

  replicate_source_db = aws_db_instance.rds_instance[0].identifier
  instance_class      = local.replica_instance_class

  publicly_accessible = false
  multi_az           = false

  enabled_cloudwatch_logs_exports = local.final_log_types
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn            = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_id : null

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.env_name}-rds-replica-${count.index + 1}"
  })
}

# CloudWatch Log Groups - Aurora
resource "aws_cloudwatch_log_group" "aurora_logs" {
  for_each = local.is_aurora ? toset(local.final_log_types) : []

  name              = "/aws/rds/cluster/${aws_rds_cluster.aurora_cluster[0].cluster_identifier}/${each.value}"
  retention_in_days = var.rds_logs_retention
  kms_key_id        = var.kms_key_id

  tags = var.tags

  depends_on = [aws_rds_cluster.aurora_cluster]
}

# CloudWatch Log Groups - RDS
resource "aws_cloudwatch_log_group" "rds_logs" {
  for_each = local.is_aurora ? [] : toset(local.final_log_types)

  name              = "/aws/rds/instance/${aws_db_instance.rds_instance[0].identifier}/${each.value}"
  retention_in_days = var.rds_logs_retention
  kms_key_id        = var.kms_key_id

  tags = var.tags

  depends_on = [aws_db_instance.rds_instance]
}
