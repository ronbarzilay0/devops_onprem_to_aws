output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance — always points to the primary (or promoted standby after failover)"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "rds_port" {
  description = "Port the RDS instance listens on"
  value       = aws_db_instance.main.port
}

output "rds_identifier" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.main.identifier
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials — pass to EC2 via IAM policy"
  value       = aws_secretsmanager_secret.db_credentials.arn
  sensitive   = true
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}
