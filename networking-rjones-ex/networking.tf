resource "aws_vpc" "web-apps" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "web-apps-vpc"
  }
}

resource "aws_subnet" "load-balancing-a" {
  cidr_block = var.load-balancing-a-cidr
  vpc_id = aws_vpc.web-apps.id
  availability_zone = "ap-south-1a"

  tags = {
    Name = "load-balancing-a"
  }
}

resource "aws_subnet" "applications-a" {
  cidr_block = var.applications-a
  vpc_id = aws_vpc.web-apps.id
  availability_zone = "ap-south-1a"

  tags = {
    Name = "applications-a"
  }
}

resource "aws_route_table" "public-traffic" {
  vpc_id = aws_vpc.web-apps.id

  tags = {
    Name = "public-traffic"
  }
}
resource "aws_internet_gateway" "web-apps-internet-access" {
  vpc_id = aws_vpc.web-apps.id

  tags = {
    Name = "web-apps-internet-access"
  }
}
resource "aws_route" "public-internet-gw-route" {
  route_table_id = aws_route_table.public-traffic.id
  gateway_id = aws_internet_gateway.web-apps-internet-access.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route_table_association" "load-balancing-rt-assoc-1" {
  route_table_id = aws_route_table.public-traffic.id
  subnet_id = aws_subnet.load-balancing-a.id
}

resource "aws_network_acl" "load-balancing-public-traffic-nacl" {
  vpc_id = aws_vpc.web-apps.id
  subnet_ids = [
    aws_subnet.load-balancing-a.id]
  egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }
  tags = {
    Name = "load-balancing-public-traffic"
  }
}

resource "aws_network_acl_rule" "lb-public-traffic-nacl-ingress-0" {
  network_acl_id = aws_network_acl.load-balancing-public-traffic-nacl.id
  rule_number = 10
  protocol = "tcp"
  rule_action = "allow"
  from_port = 22
  to_port = 22
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "lb-public-traffic-nacl-ingress-1" {
  network_acl_id = aws_network_acl.load-balancing-public-traffic-nacl.id
  rule_number = 100
  protocol = "tcp"
  rule_action = "allow"
  from_port = 80
  to_port = 80
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "lb-public-traffic-nacl-ingress-2" {
  network_acl_id = aws_network_acl.load-balancing-public-traffic-nacl.id
  rule_number = 110
  protocol = "tcp"
  rule_action = "allow"
  from_port = 443
  to_port = 443
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "lb-public-traffic-nacl-ingress-3" {
  network_acl_id = aws_network_acl.load-balancing-public-traffic-nacl.id
  rule_number = 120
  protocol = "tcp"
  rule_action = "allow"
  from_port = 1024
  to_port = 65535
  cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "load-balancer-sg" {
  vpc_id = aws_vpc.web-apps.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 1024
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = [
      "10.0.0.0/16"]
  }

  tags = {
    Name = "load-balancer-sg"
  }
}

resource "aws_security_group" "web-app-sg" {
  vpc_id = aws_vpc.web-apps.id
  ingress {
    from_port = 1024
    to_port = 65535
    protocol = "tcp"
    security_groups = [
      aws_security_group.load-balancer-sg.id]
  }
  tags = {
    Name = "web-app-sg"
  }
}