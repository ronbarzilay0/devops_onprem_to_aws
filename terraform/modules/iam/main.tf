terraform {
  required_providers = {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.0"
}
# ─────────────────────────────────────────
# EC2 IAM Role
# ─────────────────────────────────────────
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}

# ─────────────────────────────────────────
# CloudWatch Logs Policy
# Allows EC2 instances to push logs to CloudWatch
# ─────────────────────────────────────────
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.project_name}-${var.environment}-cloudwatch-logs-policy"
  description = "Allow EC2 instances to write logs and metrics to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# ─────────────────────────────────────────
# S3 Policy
# Allows EC2 instances to read app assets/configs from S3
# ─────────────────────────────────────────
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-${var.environment}-s3-policy"
  description = "Allow EC2 instances to read from the application S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-app-assets",
          "arn:aws:s3:::${var.project_name}-${var.environment}-app-assets/*"
        ]
      }
    ]
  })
}

# ─────────────────────────────────────────
# Secrets Manager Policy
# Allows EC2 instances to fetch DB credentials at runtime
# ─────────────────────────────────────────
resource "aws_iam_policy" "secrets_manager" {
  name        = "${var.project_name}-${var.environment}-secrets-policy"
  description = "Allow EC2 instances to read DB credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}-${var.environment}-db-credentials-*"
      }
    ]
  })
}

# ─────────────────────────────────────────
# Attach Policies to EC2 Role
# ─────────────────────────────────────────
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "ec2_secrets" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.secrets_manager.arn
}

# SSM managed policy — allows Session Manager access to instances (no SSH needed)
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ─────────────────────────────────────────
# Instance Profile
# Wraps the role so it can be attached to EC2 instances
# ─────────────────────────────────────────
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-instance-profile"
  }
}
