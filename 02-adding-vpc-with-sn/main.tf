provider "aws" {
  region = var.region
  #version = ">= ~2.x"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "web_vpc" {
  cidr_block = var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = false
}

resource "aws_subnet" "tier2" {
  vpc_id = aws_vpc.web_vpc.id

  count = 2
  # cidrsubnet() function splits a CIDR block into subnets
  # cidrsubnet(var.cidr_block, 1, 0) =  192.168.100.0/25
  # cidrsubnet(var.cidr_block, 1, 1) =  192.168.100.128/25
  # count.index is 0-based
  cidr_block = cidrsubnet(var.vpc_cidr_block, 1, count.index)
  availability_zone = var.azs[count.index]

  tags = {
    Name = "Web Subnet ${count.index +1}"
  }
}

resource "aws_instance" "web" {
  count = var.instance_count
  ami = var.ami
  instance_type = "t2.micro"

  subnet_id = element(aws_subnet.tier2.*.id, count.index % length(aws_subnet.tier2.*.id))
  tags = {
    Name = "Web Server ${count.index + 1}}"
  }
}