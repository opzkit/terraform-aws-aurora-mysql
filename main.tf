resource "aws_db_subnet_group" "default" {
  name       = "${var.identifier}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.identifier} DB subnet group"
  }
}

resource "aws_security_group" "allow_mysql" {
  vpc_id = var.vpc.id
  name   = "allow-mysql-${var.identifier}"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = [var.vpc.cidr_block]
  }
  # This is probably secure enough - can be removed and setup externally if needed...
  ingress {
    from_port   = 3306
    protocol    = "TCP"
    to_port     = 3306
    cidr_blocks = [var.vpc.cidr_block]
  }
}

resource "aws_rds_cluster" "default" {
  cluster_identifier      = var.identifier
  engine                  = "aurora-mysql"
  engine_version          = var.mysql_version
  availability_zones      = var.zones
  database_name           = var.db_name
  master_username         = var.master_username
  master_password         = local.password
  backup_retention_period = 14
  preferred_backup_window = "03:00-05:00"
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids = [
    aws_security_group.allow_mysql.id
  ]
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = "${var.identifier}-final"
  storage_encrypted               = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_parameters.name
  kms_key_id                      = var.kms_key_arn == "" ? null : var.kms_key_arn
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
}

resource "aws_rds_cluster_instance" "writer" {
  cluster_identifier                    = aws_rds_cluster.default.cluster_identifier
  identifier                            = "${var.identifier}-writer"
  instance_class                        = var.writer_instance_type
  engine                                = aws_rds_cluster.default.engine
  engine_version                        = aws_rds_cluster.default.engine_version
  monitoring_interval                   = var.enhanced_monitoring ? 60 : 0
  monitoring_role_arn                   = var.enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  performance_insights_kms_key_id       = var.kms_key_arn == "" ? null : var.kms_key_arn
  performance_insights_enabled          = local.performance_insights_writer_enabled
  performance_insights_retention_period = local.performance_insights_writer_enabled ? var.performance_insights_retention_period : null
}

resource "aws_rds_cluster_instance" "reader" {
  count                                 = var.reader_instance_type == null ? 0 : 1
  cluster_identifier                    = aws_rds_cluster.default.cluster_identifier
  identifier                            = "${var.identifier}-reader"
  instance_class                        = var.reader_instance_type
  engine                                = aws_rds_cluster.default.engine
  engine_version                        = aws_rds_cluster.default.engine_version
  monitoring_interval                   = var.enhanced_monitoring ? 60 : 0
  monitoring_role_arn                   = var.enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  promotion_tier                        = 1
  performance_insights_kms_key_id       = var.kms_key_arn == "" ? null : var.kms_key_arn
  performance_insights_enabled          = local.performance_insights_reader_enabled
  performance_insights_retention_period = local.performance_insights_reader_enabled ? var.performance_insights_retention_period : null
}

resource "aws_rds_cluster_parameter_group" "cluster_parameters" {
  family = "aurora-mysql5.7"
  name   = "${var.identifier}-cluster-parameters"

  dynamic "parameter" {
    for_each = merge(var.cluster_parameters, local.default_cluster_parameters)
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }
}

locals {
  default_cluster_parameters = {
    "performance_schema" = 1
  }

  performance_insights_reader_enabled = lookup(
    local.instance_types_performance_insights_enabled,
    try(regex("(db\\..*)\\..*", var.reader_instance_type)[0],
      ""
    ),
  true)
  performance_insights_writer_enabled = lookup(
    local.instance_types_performance_insights_enabled,
    try(regex("(db\\..*)\\..*", var.writer_instance_type)[0],
      ""
    ),
  true)

  instance_types_performance_insights_enabled = {
    "db.t2" : false,
    "db.t3" : false,
  }
}
