resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "my-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "tier2_sn" {
  cidr_block = var.tier2_sn_cidr_block
  vpc_id = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "tier3_sn" {
  cidr_block = var.tier3_sn_cidr_block
  vpc_id = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_route_table_association" "rta-subnet1" {
  route_table_id = aws_route_table.rtb.id
  subnet_id = aws_subnet.tier2_sn.id
}