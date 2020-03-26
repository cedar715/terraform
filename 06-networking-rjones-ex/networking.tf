resource "aws_vpc" "web-apps" {
  cidr_block = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "web-apps"
  }
}

data "aws_availability_zones" "available" {}

# naming convention: <functionality>-<AZ>
# SN exists per AZ
resource "aws_subnet" "lb-primary" {
  cidr_block = var.load-balancing-a-cidr
  vpc_id = aws_vpc.web-apps.id
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "tier1"
  }
}

resource "aws_subnet" "apps-primary" {
  cidr_block = var.applications-a
  vpc_id = aws_vpc.web-apps.id
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "tier2"
  }
}

resource "aws_internet_gateway" "web-apps-internet-access" {
  vpc_id = aws_vpc.web-apps.id
  tags = {
    Name = "web-apps"
  }
}

// BEST TO HAVE YOUR OWN ROUTE TABLE
resource "aws_route_table" "public-traffic" {
  vpc_id = aws_vpc.web-apps.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web-apps-internet-access.id
  }
  tags = {
    Name = "public-traffic"
  }
}

//ASSOCIATE SUBNET WITH ROUTE TABLE
resource "aws_route_table_association" "lb-public-traffic" {
  route_table_id = aws_route_table.public-traffic.id
  subnet_id = aws_subnet.lb-primary.id
}

resource "aws_network_acl" "lb-sn-nacl" {
  vpc_id = aws_vpc.web-apps.id
  subnet_ids = [
    aws_subnet.lb-primary.id]
  egress {
    rule_no = 100
    protocol = "tcp"
    from_port = 1024
    to_port = 65535
    cidr_block = "0.0.0.0/0"
    action = "allow"
  }
  tags = {
    Name = "load-balancing-public-traffic"
  }
}

resource "aws_network_acl_rule" "allow-http" {
  network_acl_id = aws_network_acl.lb-sn-nacl.id
  rule_number = 100
  protocol = "tcp"
  rule_action = "allow"
  egress = false
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "allow-https" {
  network_acl_id = aws_network_acl.lb-sn-nacl.id
  rule_number = 110
  protocol = "tcp"
  rule_action = "allow"
  egress = false
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_rule" "allow-response-from-ephemeral-ports" {
  network_acl_id = aws_network_acl.lb-sn-nacl.id
  rule_number = 200
  protocol = "tcp"
  rule_action = "allow"
  egress = false
  # within the VPC
  cidr_block = var.vpc_cidr
  from_port = 1024
  to_port = 65535
}

resource "aws_security_group" "lb-sg" {
  name = "lb-sg"
  description = "load balancer sg"
  vpc_id = aws_vpc.web-apps.id
  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  # no need of defining ephemeral ports as SG is stateful

  egress {
    protocol = "tcp"
    from_port = 1024
    to_port = 65535
    cidr_blocks = [
      var.vpc_cidr]
  }
}

resource "aws_security_group" "web-app-sg" {
  name = "web-app-sg"
  description = "Web app instances sg"
  vpc_id = aws_vpc.web-apps.id

  ingress {
    from_port = 1024
    to_port = 65535
    protocol = "tcp"
    # instead of specifying IP addresses, using SG
    security_groups = [
      aws_security_group.lb-sg.id]
  }
}

