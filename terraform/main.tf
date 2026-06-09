terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  #backend "s3" {
  #  bucket         = "my-aws-migration-tfstate"
  #  key            = "prod/terraform.tfstate"
  #  region         = "eu-west-1"
  #  dynamodb_table = "my-aws-migration-tfstate-lock"
  #  encrypt        = true
  #}
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# ─────────────────────────────────────────
# VPC
# ─────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ─────────────────────────────────────────
# IAM
# ─────────────────────────────────────────
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# ─────────────────────────────────────────
# ALB
# ─────────────────────────────────────────
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.iam.alb_security_group_id
}

# ─────────────────────────────────────────
# EC2 / Auto Scaling
# ─────────────────────────────────────────
module "ec2" {
  source = "./modules/ec2"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.vpc.private_subnet_ids
  instance_type         = var.instance_type
  ami_id                = var.ami_id
  ec2_instance_profile  = module.iam.ec2_instance_profile_name
  ec2_security_group_id = module.iam.ec2_security_group_id
  target_group_arn      = module.alb.target_group_arn
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
}

# ─────────────────────────────────────────
# RDS
# ─────────────────────────────────────────
module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_security_group_id = module.iam.rds_security_group_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
}
