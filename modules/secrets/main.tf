resource "aws_secretsmanager_secret" "db_secret" {
  name        = "${var.env}/crcw"
  description = "Database credentials for ${var.env}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = <<EOF
{
    "DATABASE_URL": "${var.database_url}",
    "DB_HOST": "${var.db_host}",
    "DB_NAME": "${var.db_name}",
    "DB_PASSWORD": "${var.db_password}",
    "DB_USER": "${var.db_user}"
}
EOF
}