resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "My-VPC"
    ManagedBy = "TF"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = local.cidr_block_all
    gateway_id = aws_internet_gateway.igw.id
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "tier1_1_sn_pub" {
  cidr_block = var.tier1_1_sn_cidr_block
  vpc_id = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "tier1_2_sn_pub" {
  cidr_block = var.tier1_2_sn_cidr_block
  vpc_id = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "tier2_1_sn_pvt" {
  cidr_block = var.tier2_1_sn_cidr_block
  vpc_id = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "tier2_2_sn_pvt" {
  cidr_block = var.tier2_2_sn_cidr_block
  vpc_id = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_route_table_association" "rta_sn11" {
  route_table_id = aws_route_table.rtb.id
  subnet_id = aws_subnet.tier1_1_sn_pub.id
}

resource "aws_route_table_association" "rta_sn12" {
  route_table_id = aws_route_table.rtb.id
  subnet_id = aws_subnet.tier1_2_sn_pub.id
}

resource "aws_route_table_association" "rta_sn21" {
  route_table_id = aws_route_table.rtb.id
  subnet_id = aws_subnet.tier2_1_sn_pvt.id
}

resource "aws_route_table_association" "rta_sn22" {
  route_table_id = aws_route_table.rtb.id
  subnet_id = aws_subnet.tier2_2_sn_pvt.id
}
