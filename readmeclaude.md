# AWS Migration — Infrastructure as Code

Multi-AZ AWS infrastructure for 8 microservices migrated from on-premise.
Deploys a fully HA architecture across 2 Availability Zones with auto-scaling,
Multi-AZ RDS, and a complete CI/CD pipeline via GitHub Actions.

## Architecture Summary

```
Internet → ALB (public subnets, 2 AZs)
               ↓
         EC2 Auto Scaling Group (private subnets, 2 AZs)
               ↓
         RDS PostgreSQL Multi-AZ (db subnets, 2 AZs)
```

All sensitive values (DB password, credentials) are stored in **AWS Secrets Manager** — never in code or environment variables.

## Repository Structure

```
my-aws-migration/
├── architecture.png              # Architecture diagram
├── README.md
├── .gitignore
├── terraform/
│   ├── main.tf                   # Root module — wires everything together
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example  # Copy → terraform.tfvars (never commit)
│   ├── bootstrap/
│   │   └── main.tf               # One-time S3 + DynamoDB state backend setup
│   └── modules/
│       ├── vpc/                  # VPC, subnets, IGW, NAT GWs, route tables
│       ├── ec2/                  # ALB, Security Groups, Launch Template, ASG
│       ├── rds/                  # RDS PostgreSQL Multi-AZ + Secrets Manager
│       ├── iam/                  # EC2 role, GitHub OIDC role, policies
│       └── observability/        # CloudWatch logs, alarms, SNS, dashboard
└── .github/
    └── workflows/
        ├── ci.yml                # Lint → Validate → Scan → Plan (every push/PR)
        └── cd.yml                # Plan + artifact on merge to main (no apply)
```

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | >= 1.5.0 | https://developer.hashicorp.com/terraform/install |
| AWS CLI | v2 | https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html |
| TFLint | v0.50+ | `brew install tflint` or https://github.com/terraform-linters/tflint |
| Checkov | latest | `pip install checkov` |

AWS credentials with sufficient permissions must be configured:
```bash
aws configure          # or use aws sso login
aws sts get-caller-identity   # verify you're authenticated
```

## First-Time Setup

### 1. Bootstrap the remote state backend (run once)

```bash
cd terraform/bootstrap
terraform init
terraform apply
# Note the output: state_bucket_name and lock_table_name
```

### 2. Configure your variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — fill in your account_id, ec2_ami_id, alarm_email, etc.
```

Find the latest Amazon Linux 2023 AMI for your region:
```bash
aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --query "sort_by(Images,&CreationDate)[-1].ImageId" \
  --region eu-west-1
```

### 3. Run Terraform plan locally

```bash
cd terraform
terraform init
terraform plan
```

A clean plan with no errors is the expected output. **Do not run `terraform apply`** — this is handled outside the pipeline after human review.

## GitHub Actions Setup

### Required Secrets

Add these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `AWS_OIDC_ROLE_ARN` | ARN of the GitHub Actions IAM role (output of the IAM module) |
| `AWS_ACCOUNT_ID` | Your 12-digit AWS account ID |
| `EC2_AMI_ID` | AMI ID for the EC2 launch template |
| `ALARM_EMAIL` | Email for CloudWatch alarm notifications |

### OIDC Trust Setup

The IAM module creates an OIDC provider and role automatically. After the first `terraform apply` (manual), copy the `github_actions_role_arn` output into the `AWS_OIDC_ROLE_ARN` secret.

### How to Trigger the CI Pipeline

The CI pipeline triggers automatically on:
- Every `git push` to any branch
- Every Pull Request targeting `main`

To trigger manually:
```bash
git add .
git commit -m "feat: update infrastructure"
git push origin feature/my-change
# Open a PR → CI runs automatically and posts a plan comment
```

The CD pipeline triggers on merge to `main` and saves the plan as a downloadable artifact — **it never runs `terraform apply`**.

## Key Design Decisions

**Why EC2 over ECS/Lambda?**
The workload is 8 existing Java/Node.js microservices in Docker containers. EC2 gives full control over the runtime, supports the existing Docker-based deployment model without re-architecting, and allows the team to migrate with minimal code changes.

**Why Multi-AZ RDS?**
Multi-AZ maintains a synchronous standby replica in a second AZ. AWS automatically fails over (typically < 60 seconds) if the primary fails, satisfying the 99.99% uptime SLA for the database tier.

**How is 99.99% uptime achieved?**
- ALB spans 2 AZs — survives a full AZ outage
- ASG minimum of 2 instances across 2 AZs — one instance failure is automatically replaced
- RDS Multi-AZ — automatic DB failover
- NAT Gateways deployed per-AZ — no single point of failure for outbound traffic

**Secrets management:**
All credentials are generated by Terraform, stored in AWS Secrets Manager, and fetched at instance boot via the IAM role. No secrets are ever stored in code, environment variables, or the state file (the state file is encrypted at rest in S3).
