variable "stage" {
  default = "staging"
}

variable "region" {
  default = "us-east-1a"
}

variable "amis" {
  default = {
    us-east-1 = "ami-0ff8a91507f77f867"
  }
}

variable "ec2_key_name" {
  default = "terraform"
}

variable "public_key_path" {
  default = "~/.ssh/terraform.pub"
}
