output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2.name
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2.arn
}

output "github_actions_role_arn" {
  description = "ARN for GitHub Actions to assume via OIDC"
  value       = aws_iam_role.github_actions.arn
}
