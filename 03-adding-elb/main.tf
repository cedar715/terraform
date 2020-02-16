/*

My first tf infra deploy CONFIGURATION file

HIGHLEVEL STEPS:

#1 define variables to store AWS creds
#2 define provider
#3 define data source to pull the info of the resources present in the provider
#4 define the resource that needs to be provisioned
#5 define the output

*/

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  # var is a keyword in HCL
  # every provider block has some sort of credentials to access the provider, the region to deploy the resources
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
  version = "~> 2.0"
}

##################################################################################
# DATA - pull data outside of config file. Here we are getting from provider itself
##################################################################################
data "aws_ami" "aws-linux" {
  most_recent = true
  owners = [
    "amazon"]

  filter {
    name = "name"
    values = [
      "amzn-ami-hvm*"]
  }

  filter {
    name = "root-device-type"
    values = [
      "ebs"]
  }
  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }
}

data "aws_availability_zones" "available" {}

##################################################################################
# RESOURCES THAT WILL BE PROVISIONED IN THE CLOUD
##################################################################################

## NETWORKING
resource "aws_vpc" "vpc" {
  cidr_block = var.network_address_space
  enable_dns_hostnames = "true"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet1" {
  cidr_block = var.subnet1_address_space
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  # returns multiple
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "subnet2" {
  cidr_block = var.subnet2_address_space
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]
}

## ROUTING
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-subnet1" {
  route_table_id = aws_route_table.rtb.id
  subnet_id = aws_subnet.subnet1.id
}

resource "aws_route_table_association" "rta-subnet2" {
  route_table_id = aws_route_table.rtb.id
  subnet_id = aws_subnet.subnet2.id
}

# SECURITY GROUPS
resource "aws_security_group" "nginx_sg" {
  name = "nginx_sg"
  vpc_id = aws_vpc.vpc.id

  #SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  #HTTP access from VPC
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      var.network_address_space]
  }

  #outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb-sg" {
  name = "nginx-elb-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "nginx-elb"
  subnets = [
    aws_subnet.subnet1.id,
    aws_subnet.subnet2.id]
  security_groups = [
    aws_security_group.elb-sg.id]
  instances = [
    aws_instance.nginx1.id,
    aws_instance.nginx2.id]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

# provision of new EC2 instance
resource "aws_instance" "nginx1" {
  /*
  AMI retrieved from Data Source. Instead of retrieving dynamically,
  it can be hardcoded like instance_type.
  */
  ami = data.aws_ami.aws-linux.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet1.id
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.nginx_sg.id]

  connection {
    #define conn block inside resource for allowing ssh
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    # pvt key that will be used for SSH conn
    private_key = file(var.private_key_path)
  }

  # scripts to run when resources are created/destroyed
  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "echo '<html><head><title>Blue Team Server</title></head><body style=\"background-color:#1F778D\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">Blue Team</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
    ]
  }
}

resource "aws_instance" "nginx2" {
  /*
  AMI retrieved from Data Source. Instead of retrieving dynamically,
  it can be hardcoded like instance_type.
  */
  ami = data.aws_ami.aws-linux.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet2.id
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.nginx_sg.id]

  connection {
    #define conn block inside resource for allowing ssh
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    # pvt key that will be used for SSH conn
    private_key = file(var.private_key_path)
  }

  # scripts to run when resources are created/destroyed
  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "echo '<html><head><title>Green Team Server</title></head><body style=\"background-color:#77A032\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">Green Team</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
    ]
  }
}