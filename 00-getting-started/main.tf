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

##################################################################################
# RESOURCES THAT WILL BE PROVISIONED IN THE CLOUD
##################################################################################

# making use of the default VPC in the region specified i.e we are not creating any new VPCs
##create respurce #1
resource "aws_default_vpc" "default" {}

# new security group will be created
# To allow EC2 instance to receive traffic, you need to create a SecurityGroup
# to allow ssh connectons to the instance, also open 80 port
##create respurce #2
resource "aws_security_group" "allow_ssh" {
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

# provision of new EC2 instance
##create respurce #3
resource "aws_instance" "nginx" {
  /*
  AMI retrieved from Data Source. Instead of retrieving dynamically,
  it can be hardcoded like instance_type.
  */
  ami = data.aws_ami.aws-linux.id
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id]

  connection {
    #define conn block inside resource for allowing ssh; below provisioner will be using this SSH
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
      "sudo service nginx start"
    ]
  }
}