variable "project_name" { type = string }
variable "environment"  { type = string }
variable "vpc_id"       { type = string }

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ec2_instance_type" { type = string }
variable "ec2_ami_id"        { type = string }
variable "ec2_key_name"      { type = string }
variable "ec2_instance_profile" { type = string }

variable "asg_min_size"         { type = number }
variable "asg_max_size"         { type = number }
variable "asg_desired_capacity" { type = number }

variable "microservices" {
  type = list(string)
}

variable "rds_endpoint"        { type = string }
variable "secrets_manager_arn" { type = string }

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS on the ALB"
  type        = string
  default     = ""
}
