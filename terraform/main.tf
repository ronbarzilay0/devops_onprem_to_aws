terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-aws-migration-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# ── VPC ──────────────────────────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
}

# ── IAM ───────────────────────────────────────────────────────────────────────
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = var.account_id
}

# ── RDS ───────────────────────────────────────────────────────────────────────
module "rds" {
  source = "./modules/rds"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  db_subnet_ids       = module.vpc.db_subnet_ids
  ec2_security_group_id = module.ec2.ec2_security_group_id
  db_name             = var.db_name
  db_username         = var.db_username
  db_instance_class   = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_backup_retention = var.db_backup_retention
}

# ── EC2 / ALB / ASG ───────────────────────────────────────────────────────────
module "ec2" {
  source = "./modules/ec2"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  ec2_instance_type     = var.ec2_instance_type
  ec2_ami_id            = var.ec2_ami_id
  ec2_key_name          = var.ec2_key_name
  ec2_instance_profile  = module.iam.ec2_instance_profile_name
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
  microservices         = var.microservices
  rds_endpoint          = module.rds.rds_endpoint
  secrets_manager_arn   = module.rds.db_secret_arn
}

# ── Observability ─────────────────────────────────────────────────────────────
module "observability" {
  source = "./modules/observability"

  project_name    = var.project_name
  environment     = var.environment
  microservices   = var.microservices
  alb_arn_suffix  = module.ec2.alb_arn_suffix
  asg_names       = module.ec2.asg_names
  alarm_email     = var.alarm_email
}
