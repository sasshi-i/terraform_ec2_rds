variable "stage" {}

resource "aws_vpc" "qiita_vpc" {
  cidr_block                       = "10.8.0.0/16"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "qiita_ec2_rds"
  }
}

resource "aws_subnet" "qiita_subnet_1a" {
  count             = 2
  vpc_id            = aws_vpc.qiita_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.qiita_vpc.cidr_block, 8, count.index)
  availability_zone = "us-east-1a"

  tags = {
    Name = "qiita-${var.stage}-us-east-1a"
  }
}

resource "aws_subnet" "qiita_subnet_1b" {
  count             = 2
  vpc_id            = aws_vpc.qiita_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.qiita_vpc.cidr_block, 8, count.index+2)
  availability_zone = "us-east-1b"

  tags = {
    Name = "qiita-${var.stage}-us-east-1b"
  }
}

resource "aws_internet_gateway" "qiita_igw" {
  vpc_id = aws_vpc.qiita_vpc.id
  tags = {
    Name = "igw-${var.stage}"
  }
}

resource "aws_route_table" "qiita_rtb_public" {
  vpc_id = aws_vpc.qiita_vpc.id
  tags = {
    Name = "rtb-${var.stage}-public"
  }
}

resource "aws_route_table_association" "qiita_rtb_assoc_pblic" {
  count          = 2
  route_table_id = aws_route_table.qiita_rtb_public.id
  subnet_id      = element([aws_subnet.qiita_subnet_1a[0].id, aws_subnet.qiita_subnet_1b[0].id], count.index)
}

resource "aws_route" "qiita_route_igw" {
  route_table_id         = aws_route_table.qiita_rtb_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.qiita_igw.id
  depends_on             = [aws_route_table.qiita_rtb_public]
}

resource "aws_route_table" "qiita_rtb_private" {
  vpc_id = aws_vpc.qiita_vpc.id
  tags = {
    Name = "rtb-${var.stage}-private"
  }
}

resource "aws_route_table_association" "qiita_rtb_assoc_private" {
  count          = 2
  route_table_id = aws_route_table.qiita_rtb_private.id
  subnet_id      = element([aws_subnet.qiita_subnet_1a[1].id, aws_subnet.qiita_subnet_1b[1].id], count.index)
}

