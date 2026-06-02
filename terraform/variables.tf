variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment (prod / staging / dev)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Short project identifier used in resource names"
  type        = string
  default     = "aws-migration"
}

# ── Network ───────────────────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use (minimum 2)"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private (app) subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for private DB subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

# ── EC2 / ASG ─────────────────────────────────────────────────────────────────
variable "ec2_instance_type" {
  description = "EC2 instance type for the microservice hosts"
  type        = string
  default     = "t3.medium"
}

variable "ec2_ami_id" {
  description = "Amazon Machine Image ID (Amazon Linux 2023 recommended)"
  type        = string
}

variable "ec2_key_name" {
  description = "EC2 key pair name for SSH access (leave empty to disable)"
  type        = string
  default     = ""
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
  default     = 10
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances at steady state"
  type        = number
  default     = 2
}

variable "microservices" {
  description = "List of microservice names to deploy (used for log groups, target groups, etc.)"
  type        = list(string)
  default = [
    "user-service",
    "order-service",
    "payment-service",
    "inventory-service",
    "notification-service",
    "auth-service",
    "product-service",
    "gateway-service"
  ]
}

# ── RDS ───────────────────────────────────────────────────────────────────────
variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "dbadmin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.large"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 500
}

variable "db_backup_retention" {
  description = "Number of days to retain automated RDS backups"
  type        = number
  default     = 7
}

# ── Observability ─────────────────────────────────────────────────────────────
variable "alarm_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}
