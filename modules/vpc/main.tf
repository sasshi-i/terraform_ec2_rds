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

resource "aws_route_table_association" "qiita_rtb_assoc_public" {
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

resource "aws_default_network_acl" "qiita_default_acl" {
  default_network_acl_id = "${aws_vpc.qiita_vpc.default_network_acl_id}"

  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "all"
    rule_no    = 101
    action     = "allow"
    ipv6_cidr_block = "::/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "all"
    rule_no    = 101
    action     = "allow"
    ipv6_cidr_block = "::/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "qiita_acl"
  }
}

resource "aws_security_group" "alb" {
  name        = "qiita-${var.stage}-alb"
  description = "security group for ALB"
  vpc_id      = "${aws_vpc.qiita_vpc.id}"
  tags        = { 
    Name = "qiita-${var.stage}-alb" 
  }
}

resource "aws_security_group_rule" "alb-ingress-ipv4" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
}

resource "aws_security_group_rule" "alb-ingress-ipv6" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  ipv6_cidr_blocks  = ["::/0"]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
}

resource "aws_security_group_rule" "alb-egress-ipv4" {
  security_group_id = aws_security_group.alb.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "all"
}

resource "aws_security_group_rule" "alb-egress-ipv6" {
  security_group_id = aws_security_group.alb.id
  type              = "egress"
  ipv6_cidr_blocks  = ["::/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "all"
}


resource "aws_security_group" "ec2" {
  name        = "qiita-${var.stage}-ec2"
  description = "security group for EC2"
  vpc_id      = "${aws_vpc.qiita_vpc.id}"
  tags        = { 
    Name = "qiita-${var.stage}-ec2" 
  }
}

resource "aws_security_group_rule" "ec2-ingress" {
  security_group_id        = aws_security_group.ec2.id
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb.id
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
}

resource "aws_security_group_rule" "ec2-egress_ipv4" {
  security_group_id = aws_security_group.ec2.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "all"
}

resource "aws_security_group_rule" "ec2-egress_ipv6" {
  security_group_id = aws_security_group.ec2.id
  type              = "egress"
  ipv6_cidr_blocks  = ["::/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "all"
}

resource "aws_security_group" "rds" {
  name        = "qiita-${var.stage}-rds"
  description = "security group for RDS"
  vpc_id      = "${aws_vpc.qiita_vpc.id}"
  tags        = { 
    Name = "qiita-${var.stage}-rds" 
  }
}

resource "aws_security_group_rule" "rds-ingress" {
  security_group_id        = aws_security_group.rds.id
  type                     = "ingress"
  source_security_group_id = aws_security_group.ec2.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "rds-egress_ipv4" {
  security_group_id = aws_security_group.rds.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "all"
}

resource "aws_security_group_rule" "rds-egress_ipv6" {
  security_group_id = aws_security_group.rds.id
  type              = "egress"
  ipv6_cidr_blocks  = ["::/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "all"
}
