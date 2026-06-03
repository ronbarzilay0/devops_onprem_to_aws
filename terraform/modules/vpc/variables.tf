variable "project_name" {
  description = "Project name used as a prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging, dev)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets — must match the number of AZs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets — must match the number of AZs"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to deploy into (minimum 2)"
  type        = list(string)
}
