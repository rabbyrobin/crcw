variable "env" { type = string }
variable "vpc_id" { type = string }
variable "subnets" { type = list(string) }
variable "db_security_group_ids" { type = list(string) }
variable "db_username" { type = string }
variable "db_password" { type = string }
variable "db_name" { type = string }
