variable "project_name" {
  description = "Project name used as a prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging, dev)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC — from the vpc module output"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets to place the DB subnet group in — from the vpc module output"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "ID of the EC2 security group — RDS only accepts inbound from this SG"
  type        = string
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS instance — pass in via environment variable or Secrets Manager, never hardcode"
  type        = string
  sensitive   = true
  default     = "placeholder-for-validation-only"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS in GB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Maximum storage RDS can autoscale up to in GB"
  type        = number
  default     = 500
}
