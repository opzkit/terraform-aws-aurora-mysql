output "database_secret_name" {
  value = aws_secretsmanager_secret.aurora_secret.name
}
