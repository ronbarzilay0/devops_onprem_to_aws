output "alb_dns_name" {
  description = "DNS name of the ALB — use this to reach the application"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB — needed for Route53 alias records"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group — passed to the ec2 module for ASG attachment"
  value       = aws_lb_target_group.main.arn
}

output "alb_security_group_id" {
  description = "ID of the ALB security group — passed to ec2 module to allow inbound only from ALB"
  value       = aws_security_group.alb.id
}
