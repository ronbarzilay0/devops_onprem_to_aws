# ─────────────────────────────────────────
# Networking
# ─────────────────────────────────────────
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# ─────────────────────────────────────────
# Load Balancer
# ─────────────────────────────────────────
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer — use this to reach the app"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

# ─────────────────────────────────────────
# Compute
# ─────────────────────────────────────────
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.ec2.asg_name
}

# ─────────────────────────────────────────
# Database
# ─────────────────────────────────────────
output "rds_endpoint" {
  description = "Connection endpoint for the RDS PostgreSQL instance"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "rds_port" {
  description = "Port the RDS instance listens on"
  value       = module.rds.rds_port
}

# ─────────────────────────────────────────
# Secrets
# ─────────────────────────────────────────
output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials"
  value       = module.rds.db_secret_arn
  sensitive   = true
}
