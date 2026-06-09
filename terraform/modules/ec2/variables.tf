variable "project_name" {
  description = "Project name used as a prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging, dev)"
  type        = string
}

variable "aws_region" {
  description = "AWS region — passed into user_data for CloudWatch agent config"
  type        = string
  default     = "eu-west-1"
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets to launch EC2 instances in — from the vpc module output"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ec2_instance_profile" {
  description = "Name of the IAM instance profile to attach — from the iam module output"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group — ASG registers instances here"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 10
}

variable "asg_desired_capacity" {
  description = "Desired number of instances at launch"
  type        = number
  default     = 2
}
