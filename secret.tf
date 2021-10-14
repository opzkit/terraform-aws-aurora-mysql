resource "aws_secretsmanager_secret" "aurora_secret" {
  name = "rds/mysql/${var.identifier}"
}

resource "aws_secretsmanager_secret_version" "aurora_secret_value" {
  secret_id     = aws_secretsmanager_secret.aurora_secret.id
  secret_string = jsonencode(local.secret_value)
}

locals {
  secret_value = {
    DB_USERNAME = var.master_username
    DB_PASSWORD = local.password
    DB_NAME     = aws_rds_cluster.default.cluster_identifier
    DB_PORT     = aws_rds_cluster.default.port
    DB_HOST     = aws_rds_cluster.default.endpoint
  }
  password = random_password.password.result
}

resource "random_password" "password" {
  length           = 32
  special          = false
  lower            = true
  upper            = true
  number           = true
  override_special = ""
  min_special      = 0
  min_lower        = 5
  min_upper        = 5
  min_numeric      = 5
  lifecycle {
    ignore_changes = all
  }
}
