#############################################
# RDS CPU Utilization Alarm
#############################################
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  alarm_name          = "${var.project_name}-${var.env_name}-rds-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = local.is_aurora ? {
    DBClusterIdentifier = aws_rds_cluster.aurora_cluster[0].cluster_identifier
  } : {
    DBInstanceIdentifier = aws_db_instance.rds_instance[0].identifier
  }

  tags = var.tags
}

#############################################
# RDS Database Connections Alarm
#############################################
resource "aws_cloudwatch_metric_alarm" "rds_database_connections" {
  alarm_name          = "${var.project_name}-${var.env_name}-rds-database-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS database connections"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = local.is_aurora ? {
    DBClusterIdentifier = aws_rds_cluster.aurora_cluster[0].cluster_identifier
  } : {
    DBInstanceIdentifier = aws_db_instance.rds_instance[0].identifier
  }

  tags = var.tags
}

#############################################
# RDS Free Storage Space Alarm
#############################################
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_space" {
  count = local.is_aurora ? 0 : 1  # Only for RDS instances, not Aurora

  alarm_name          = "${var.project_name}-${var.env_name}-rds-free-storage-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2000000000"  # 2GB in bytes
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds_instance[0].identifier
  }

  tags = var.tags
}

#############################################
# RDS Freeable Memory Alarm
#############################################
resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory" {
  alarm_name          = "${var.project_name}-${var.env_name}-rds-freeable-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000"  # 100MB in bytes
  alarm_description   = "This metric monitors RDS freeable memory"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = local.is_aurora ? {
    DBClusterIdentifier = aws_rds_cluster.aurora_cluster[0].cluster_identifier
  } : {
    DBInstanceIdentifier = aws_db_instance.rds_instance[0].identifier
  }

  tags = var.tags
}

#############################################
# RDS Read Latency Alarm
#############################################
resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "${var.project_name}-${var.env_name}-rds-read-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "0.2"  # 200ms
  alarm_description   = "This metric monitors RDS read latency"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = local.is_aurora ? {
    DBClusterIdentifier = aws_rds_cluster.aurora_cluster[0].cluster_identifier
  } : {
    DBInstanceIdentifier = aws_db_instance.rds_instance[0].identifier
  }

  tags = var.tags
}

#############################################
# RDS Write Latency Alarm
#############################################
resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name          = "${var.project_name}-${var.env_name}-rds-write-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "0.2"  # 200ms
  alarm_description   = "This metric monitors RDS write latency"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = local.is_aurora ? {
    DBClusterIdentifier = aws_rds_cluster.aurora_cluster[0].cluster_identifier
  } : {
    DBInstanceIdentifier = aws_db_instance.rds_instance[0].identifier
  }

  tags = var.tags
}
