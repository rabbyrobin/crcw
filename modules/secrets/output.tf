output "secret_id" {
  description = "The ARN of the created Secrets Manager secret."
  value       = aws_secretsmanager_secret.db_secret.arn
}