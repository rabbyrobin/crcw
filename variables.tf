variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "app_name" {
  description = "Application name (e.g., crcwc-app)"
  type        = string
  default     = "crcwc-app"
}

variable "container_image_tag" {
  description = "Tag for the Container image (e.g., 1.10.51 or latest)"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "task_cpu" {
  description = "Task CPU units (e.g., 2048)"
  type        = string
}

variable "task_memory" {
  description = "Task memory (e.g., 4096)"
  type        = string
}

# --- Infrastructure Creation Variables ---
variable "vpc_cidr_block" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets_cidr" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "azs" {
  description = "List of Availability Zones to use"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# --- RDS Module Variables (Credentials) ---
variable "db_name"      { type = string }
variable "db_password"  { type = string }
variable "db_user"      { type = string }