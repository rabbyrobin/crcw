terraform {
  backend "s3" {
    bucket         = "crcwc-ecs-template-backend-prod" 
    key            = "crcwc-tf-state-file/prod/terraform.tfstate" 
    region         = "us-west-2"
    encrypt        = true
  }
}
