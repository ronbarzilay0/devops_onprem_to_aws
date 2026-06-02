#!/bin/bash
set -euo pipefail

# ── System update ─────────────────────────────────────────────────────────────
yum update -y

# ── Install Docker ────────────────────────────────────────────────────────────
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# ── Install AWS CLI v2 (already present on AL2023, but ensure latest) ─────────
# and the CloudWatch agent
yum install -y amazon-cloudwatch-agent

# ── Fetch DB credentials from Secrets Manager ─────────────────────────────────
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "${secrets_manager_arn}" \
  --region "${aws_region}" \
  --query SecretString \
  --output text)

DB_PASSWORD=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
DB_USERNAME=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")

# ── Write environment file (not committed to code, lives only on instance) ───
cat > /etc/app/env.conf <<EOF
DB_HOST=${rds_endpoint}
DB_USER=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
DB_NAME=appdb
AWS_REGION=${aws_region}
ENVIRONMENT=${environment}
EOF
chmod 600 /etc/app/env.conf
mkdir -p /etc/app

# ── CloudWatch Agent config ───────────────────────────────────────────────────
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app/*.log",
            "log_group_name": "/app/${project_name}-${environment}",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${project_name}/${environment}",
    "metrics_collected": {
      "cpu": { "measurement": ["cpu_usage_active"] },
      "mem": { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["disk_used_percent"] }
    }
  }
}
CWEOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# ── Pull and start the gateway / router container ─────────────────────────────
# In a real pipeline this image tag comes from the CI artifact or SSM Parameter
docker pull "${project_name}/gateway-service:latest" || true

mkdir -p /var/log/app

echo "Bootstrap complete – instance ready."
