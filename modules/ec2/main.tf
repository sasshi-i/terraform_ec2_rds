variable "stage" {}
variable "region" {}
variable "amis" {}
variable "ec2_key_name" {}
variable "public_key_path" {}


resource "aws_instance" "qiita_ec2_1a" {
  ami                     = lookup(var.amis, var.region)
  instance_type           = "t2.micro"
  availability_zone       = "us-east-1a"
  disable_api_termination = true
  security_groups         = [aws_security_group.ec2.id]
  key_name                = aws_key_pair.auth.id

  tags = {
    Name = "ec2-${var.stage}-us-east-1a"
  }
}

resource "aws_instance" "qiita_ec2_1b" {
  ami                     = lookup(var.amis, var.region)
  instance_type           = "t2.micro"
  availability_zone       = "us-east-1b"
  disable_api_termination = true
  security_groups         = [aws_security_group.ec2.id]
  key_name                = aws_key_pair.auth.id

  tags = {
    Name = "ec2-${var.stage}-us-east-1a"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = var.ec2_key_name
  public_key = file(var.public_key_path)
}
