output "database_secret_name" {
  value = aws_secretsmanager_secret.aurora_secret.name
}

output "security_group" {
  value = aws_security_group.allow_mysql
}
