# AWS Cloud Migration — Infrastructure as Code

Migration of an on-premise microservices platform to AWS using Terraform and GitHub Actions CI/CD.

---

## Architecture Overview

The infrastructure runs across 2 Availability Zones in `eu-west-1` for high availability:

- **VPC** — isolated network with public and private subnets across 2 AZs
- **ALB** — internet-facing Application Load Balancer in public subnets, HTTPS only
- **EC2 Auto Scaling Group** — instances in private subnets, traffic only from ALB
- **RDS PostgreSQL** — Multi-AZ database in private subnets, encrypted at rest
- **IAM** — least-privilege roles for EC2, RDS monitoring, and GitHub OIDC
- **CloudWatch** — log groups and alarms for CPU and storage thresholds
- **Secrets Manager** — stores DB credentials, never committed to code

See `architecture.png` for the full diagram.

---

## Repository Structure

my-aws-migration/
├── architecture.png          # Architecture diagram
├── README.md                 # This file
├── terraform/
│   ├── main.tf               # Root module — wires all modules together
│   ├── variables.tf          # All input variables
│   ├── outputs.tf            # Key outputs: ALB DNS, RDS endpoint, VPC ID
│   └── modules/
│       ├── vpc/              # VPC, subnets, IGW, NAT, route tables
│       ├── ec2/              # Launch template, ASG, CloudWatch alarms
│       ├── alb/              # ALB, target group, HTTP/HTTPS listeners
│       ├── rds/              # RDS PostgreSQL, subnet group, parameter group
│       └── iam/              # IAM roles, policies, instance profile
└── .github/
└── workflows/
├── ci.yml            # CI pipeline — lint, validate, security scan, plan
└── cd.yml            # CD pipeline — plan on merge to main, artifact upload



---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with credentials
- [TFLint](https://github.com/terraform-linters/tflint) v0.50.3+
- Git

---

## How to Run Terraform Plan Locally

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/devops_onprem_to_aws.git
cd devops_onprem_to_aws/terraform

# 2. Initialize Terraform (skip S3 backend — concept only, no real bucket)
terraform init -backend=false

# 3. Run the plan
terraform plan

# 4. Review the output — no apply needed
```

> **Note:** `terraform apply` is never run — plan output is sufficient for this project.

---

## How to Trigger the CI Pipeline

The CI pipeline runs automatically on every push to any branch and on all pull requests to `main`.

```bash
# Any push triggers the pipeline
git add .
git commit -m "your message"
git push
```

Pipeline stages in order:
1. **Lint & Format** — `terraform fmt` + TFLint
2. **Terraform Validate** — syntax check
3. **Security Scan** — Checkov scans for secrets, open security groups, unencrypted resources
4. **Terraform Plan** — generates and uploads plan output

The CD pipeline triggers only on merge to `main` and uploads the plan as a downloadable artifact.

---

## GitHub Actions Secrets

| Secret | Description |
|--------|-------------|
| `AWS_OIDC_ROLE_ARN` | ARN of the IAM role for GitHub OIDC authentication |

> All secrets are stored in GitHub Actions Secrets — never committed to code.

---

## Key Design Decisions

| Decision | Reason |
|----------|--------|
| EC2 over ECS/Lambda | Containerized microservices needing persistent config and full OS control |
| Multi-AZ RDS | Automatic failover if one AZ goes down — required for 99.99% SLA |
| Private subnets for EC2/RDS | Never directly reachable from internet — traffic flows through ALB only |
| NAT Gateway per AZ | Instances can reach internet (Docker pulls, AWS APIs) without being exposed |
| IMDSv2 enforced | Blocks SSRF attacks that could steal instance credentials |
| Secrets Manager for DB creds | Credentials fetched at runtime — never stored in code or environment variables |
