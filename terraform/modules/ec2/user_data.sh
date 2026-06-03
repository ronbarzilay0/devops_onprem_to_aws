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
# Sets log driver to forward container logs to CloudWatch
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
