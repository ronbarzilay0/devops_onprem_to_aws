output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private app subnets"
  value       = module.vpc.private_subnet_ids
}

output "db_subnet_ids" {
  description = "IDs of the private DB subnets"
  value       = module.vpc.db_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ec2.alb_dns_name
}

output "rds_endpoint" {
  description = "Endpoint of the RDS PostgreSQL instance"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials"
  value       = module.rds.db_secret_arn
}

output "ec2_instance_profile_name" {
  description = "Name of the IAM instance profile attached to EC2 instances"
  value       = module.iam.ec2_instance_profile_name
}

output "asg_names" {
  description = "Names of the Auto Scaling Groups"
  value       = module.ec2.asg_names
}

output "cloudwatch_log_groups" {
  description = "Names of CloudWatch Log Groups per microservice"
  value       = module.observability.log_group_names
}
