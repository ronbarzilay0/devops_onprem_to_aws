#!/bin/bash
set -euo pipefail
# ─────────────────────────────────────────
# System update
# ─────────────────────────────────────────
yum update -y
# ─────────────────────────────────────────
# Install Docker
# ─────────────────────────────────────────
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
# ─────────────────────────────────────────
# Install CloudWatch Agent
# Forwards container logs to the log group created by Terraform
# ─────────────────────────────────────────
yum install -y amazon-cloudwatch-agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/*.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/docker",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${project_name}/${environment}",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      }
    }
  }
}
EOF
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent
# ─────────────────────────────────────────
# Install AWS CLI v2 (for pulling secrets at runtime)
# ─────────────────────────────────────────
yum install -y awscli
# ─────────────────────────────────────────
# Docker daemon config
# Sets default log driver to awslogs
# Each container will override with its own log group via --log-opt
# ─────────────────────────────────────────
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "awslogs",
  "log-opts": {
    "awslogs-region": "${aws_region}",
    "awslogs-group": "${log_group_name}",
    "awslogs-stream": "docker-{container_name}"
  }
}
EOF
systemctl restart docker
# ─────────────────────────────────────────
# Fetch DB credentials from Secrets Manager at runtime
# Never hardcoded — pulled fresh on every boot
# ─────────────────────────────────────────
DB_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "${project_name}-${environment}-db-credentials" \
  --region "${aws_region}" \
  --query SecretString \
  --output text)

DB_HOST=$(echo $DB_SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])")
DB_PASS=$(echo $DB_SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
# ─────────────────────────────────────────
# Pull and run microservice containers
# Each service gets its own port and its own CloudWatch log group
# Log groups are pre-created by Terraform in ec2/main.tf
# ─────────────────────────────────────────
declare -A SERVICES=(
  ["service-users"]="8001"
  ["service-orders"]="8002"
  ["service-inventory"]="8003"
  ["service-payments"]="8004"
  ["service-notifications"]="8005"
  ["service-auth"]="8006"
  ["service-gateway"]="8007"
  ["service-reports"]="8008"
)

for SERVICE_NAME in "${!SERVICES[@]}"; do
  PORT="${SERVICES[$SERVICE_NAME]}"
  docker run -d \
    --name "$SERVICE_NAME" \
    --restart unless-stopped \
    -p "$PORT:$PORT" \
    -e DB_HOST="$DB_HOST" \
    -e DB_PASSWORD="$DB_PASS" \
    -e AWS_REGION="${aws_region}" \
    -e ENVIRONMENT="${environment}" \
    --log-driver awslogs \
    --log-opt awslogs-region="${aws_region}" \
    --log-opt awslogs-group="/aws/ec2/${project_name}-${environment}/$SERVICE_NAME" \
    --log-opt awslogs-stream="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" \
    "${project_name}/$SERVICE_NAME:latest"
done
