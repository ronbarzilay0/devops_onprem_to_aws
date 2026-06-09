output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for application logs"
  value       = "/aws/ec2/${var.project_name}-${var.environment}"
}
