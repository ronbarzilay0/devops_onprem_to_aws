output "rds_endpoint" {
  description = "Writer endpoint of the RDS instance"
  value       = aws_db_instance.postgres.address
  sensitive   = true
}

output "rds_port" {
  value = aws_db_instance.postgres.port
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret with DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}
