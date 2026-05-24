output "role_arn" {
  description = "ARN of the deploy role."
  value       = aws_iam_role.this.arn
}
