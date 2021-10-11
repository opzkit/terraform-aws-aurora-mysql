resource "aws_db_subnet_group" "default" {
  name       = "${var.identifier}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.identifier} DB subnet group"
  }
}

data "aws_security_group" "security_groups" {
  for_each = toset(var.security_group_names)
  name     = each.value
}

resource "aws_security_group" "allow_mysql" {
  vpc_id = var.vpc_id
  name   = "allow-mysql-${var.identifier}"
  ingress {
    from_port       = 3306
    protocol        = "tcp"
    to_port         = 3306
    security_groups = [for i, g in data.aws_security_group.security_groups : g.id]
  }

  egress {
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    security_groups = [for i, g in data.aws_security_group.security_groups : g.id]
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
  aws_security_group.allow_mysql.id]
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${var.identifier}-final"
}

resource "aws_rds_cluster_instance" "writer" {
  cluster_identifier = aws_rds_cluster.default.cluster_identifier
  identifier         = "${var.identifier}-writer"
  instance_class     = var.writer_instance_type
  engine             = aws_rds_cluster.default.engine
  engine_version     = aws_rds_cluster.default.engine_version
}
