# --- DATA: AWS Environment Context ---
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

# --- 1. DYNAMIC NETWORK CREATION ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "crcwc-vpc-${var.environment}"
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets_cidr
  
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "crcwc-vpc-${var.environment}"
    Environment = var.environment
  }
}

# --- 2. DYNAMIC SECURITY GROUP CREATION ---
resource "aws_security_group" "alb" {
  name        = "crcwc-alb-sg-${var.environment}"
  description = "Allow traffic to ALB"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "crcwc-alb-sg-${var.environment}"
  }
}

resource "aws_security_group" "ecs" {
  name        = "crcwc-ecs-sg-${var.environment}"
  description = "Allow traffic from ALB to ECS"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "crcwc-ecs-sg-${var.environment}"
  }
}

# --- 3. DYNAMIC IAM ROLE CREATION ---
resource "aws_iam_role" "task" {
  name = "csr-EcsTask-Role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "execution" {
  name = "csr-EcsExecution-Role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
  # NOTE: Attach required policies (ECR, Logs, Secrets) here.
}

# --- 4. DYNAMIC RDS & SECRETS CREATION ---
module "rds" {
    source = "./modules/rds" 
    env = var.environment
    vpc_id = module.vpc.vpc_id
    subnets = module.vpc.private_subnets
    db_username = var.db_user
    db_password = var.db_password
    db_name = var.db_name
    db_security_group_ids = [aws_security_group.ecs.id] 
}

# --- 5. ECS & Service Discovery ---
data "aws_ecr_repository" "app" {
  name = var.ecr_repository_name
}

resource "aws_service_discovery_http_namespace" "app_namespace" {
  name = "${var.environment}-namespace"
}

locals {
  container_image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${data.aws_ecr_repository.app.name}:${var.container_image_tag}"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "crcwc-webapp"
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.app_namespace.arn
  }
  tags = {}
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  
  container_definitions = templatefile("./modules/ecs/templates/ecs/task_defination_id.json.tpl", {
    env               = var.environment
    app_image         = local.container_image_uri
    fargate_cpu       = var.task_cpu
    fargate_memory    = var.task_memory
    aws_region        = data.aws_region.current.name
    # Secret ARN output from the RDS module, which calls the secrets module internally
    secret_id         = module.rds.secret_arn 
  })
}

# ECS Service
resource "aws_ecs_service" "crcwc_service" {
    name = "crcwc_service"
    cluster =  aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.app.arn
    launch_type = "FARGATE"
    desired_count = 1
    force_new_deployment = true
    
    load_balancer {
      target_group_arn=  module.alb.target_group_arns[0]
      container_name = var.app_name
      container_port = 8080
    }

    network_configuration {
    subnets = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
    }
}