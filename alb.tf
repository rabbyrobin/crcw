module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "crcwc-alb-${var.environment}"

  load_balancer_type = "application"

  # Use module outputs and created SGs
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets 
  security_groups    = [aws_security_group.alb.id]

  target_groups = [
   {
      name = "crcwc-alb-http"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      health_check = {
        path = "/crcwc"
        healthy_threshold   = 3
        interval            = 60
        unhealthy_threshold = 10
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
}

output "alb_arn_output"{
  description = "arn for the alb"
  value = module.alb.lb_arn
}