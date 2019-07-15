module "provider" {
  source            = "../modules/provider"
}

module "vpc" {
  source = "../modules/vpc"
  stage  = var.stage
}
