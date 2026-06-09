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

variable "public_subnet_ids" {
  description = "IDs of the public subnets to place the ALB in — from the vpc module output"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "The ID of the the ALB security group"
  type        = string
}

variable "app_port" {
  description = "Port the microservice containers listen on inside EC2"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "HTTP path the ALB uses to health check targets"
  type        = string
  default     = "/health"
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS — must exist before terraform plan"
  type        = string
  default     = "arn:aws:acm:eu-west-1:123456789012:certificate/placeholder"
}
