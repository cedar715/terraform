provider "aws" {
  region = var.region
  secret_key = var.aws_secret_key
  access_key = var.aws_access_key
  version = "~> 2.56"
}

terraform {
  backend "s3" {
    bucket = "tfur-state-20200404"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "tf-lock"
    encrypt = true
  }
}

resource "aws_default_vpc" "default" {}

resource "aws_instance" "test_instance" {
  ami = var.ami
  instance_type = var.instance_type
  # THERE CAN BE MULTIPLE SG'S ASSOCIATED WITH AN INSTANCE. HENCE, A LIST
  # If you are creating Instances in a VPC, use vpc_security_group_ids instead of security_groups.
  vpc_security_group_ids = [
    aws_security_group.allow_web.id]
  # HEREDOC SYNTAX - CAN CR8 MULTI-LINE STR W/O NEWLINE CHAR
  # RUN THE CONTENT IN A SHELL SCRIPT BUT THE LET THE PROCESS OUTLIVE THE SHELL (nohup, &)
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, Sai!" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  tags = {
    Name = "Test Instance"
  }
}