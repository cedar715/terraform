# my first tf infra deploy file

# highlevel steps"

#1 define variables to store AWS creds
#2 define provider
#3 define data source to pull the info of the resources present in the provider
#4 define the resource that needs to be provisioned
#5 define the output

##################################################################################
# VARIABLES
##################################################################################
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {
  description = "path to the private key that corresponds to the key pair that's in AWS."
}
variable "key_name" {
  description = "key pair that exists within AWS; so that we can SSH into this instance once created"
}
variable "region" {
  default = "ap-south-1"
  description = "region to deploy the resources"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  # var is a keyword
  secret_key = var.aws_secret_key
  region = var.region
}

##################################################################################
# DATA - pull data from provider
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

##################################################################################
# RESOURCES
##################################################################################

resource "aws_default_vpc" "default" {}
# making use of the default VPC in the region specified i.e we are not creating any new VPCs

resource "aws_security_group" "allow_ssh" {
  # to allow ssh connectons to the instance, also open 80 port
  name = "nginx_demo"
  description = "Allow ports for nginx demo"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port = 22
    to_port = 22
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
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "0.0.0.0/0"]
  }

}

resource "aws_instance" "nginx" {
  ami = data.aws_ami.aws-linux.id
  #AMI retrieved from Data Source
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id]

  connection {
    #define conn block inside resource for allowing ssh
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_path)
    # pvt key that will be used for SSH conn
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start"
    ]
  }
}

##################################################################################
# OUTPUT
##################################################################################
output "aws_instance_public_dns" {
  value = aws_instance.nginx.public_dns
}


