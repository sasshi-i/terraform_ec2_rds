variable "stage" {}
data "aws_availability_zones" "available" {}

resource "aws_vpc" "qiita_ec2_rds_vpc" {
  cidr_block                       = "10.8.0.0/16"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "qiita_ec2_rds"
  }
}

resource "aws_subnet" "qiita_ec2_subnet_1a" {
  count             = 2
  vpc_id            = aws_vpc.qiita_ec2_rds_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.qiita_ec2_rds_vpc.cidr_block, 8, count.index)
  availability_zone = "us-east-1a"

  tags = {
    Name = "qiita-${var.stage}-us-east-1a"
  }
}

resource "aws_subnet" "qiita_ec2_subnet_1b" {
  count             = 2
  vpc_id            = aws_vpc.qiita_ec2_rds_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.qiita_ec2_rds_vpc.cidr_block, 8, count.index+2)
  availability_zone = "us-east-1b"

  tags = {
    Name = "qiita-${var.stage}-us-east-1b"
  }
}
