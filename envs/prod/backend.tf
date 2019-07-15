terraform {
  backend "s3" {
    bucket = "ec2-rds-deploy"
    key    = "terraform/prod.tfstate"
    region = "us-east-1"
  }
}
