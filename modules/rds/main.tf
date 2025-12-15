resource "aws_db_subnet_group" "default" {
  name        = "crcwc-subgroup-${var.env}"
  subnet_ids  = var.subnets

  tags = {
    Name = "CRCWC Subnet Group ${var.env}"
  }
}

resource "aws_db_instance" "app_db" {
  identifier             = "crcwc-${var.env}-db"
  allocated_storage      = 50
  engine                 = "postgres"
  engine_version         = "16.8"
  instance_class         = "db.m5.large"
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  vpc_security_group_ids = var.db_security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.default.name
  skip_final_snapshot    = true
}

module "db_secret_storage" {
    source = "../secrets"
    env = var.env
    
    # Credentials and Host are dynamic outputs
    database_url = format("jdbc:postgresql://%s/%s", aws_db_instance.app_db.address, var.db_name)
    db_host = aws_db_instance.app_db.address
    db_name = var.db_name
    db_password = var.db_password
    db_user = var.db_username
}

output "db_address" {
    value = aws_db_instance.app_db.address
}
output "secret_arn" {
    value = module.db_secret_storage.secret_id
}