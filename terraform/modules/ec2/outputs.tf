output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  description = "ARN suffix used by CloudWatch metrics"
  value       = aws_lb.main.arn_suffix
}

output "asg_names" {
  description = "Names of all Auto Scaling Groups"
  value       = [aws_autoscaling_group.app.name]
}

output "ec2_security_group_id" {
  description = "Security group ID attached to EC2 instances"
  value       = aws_security_group.ec2.id
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}
