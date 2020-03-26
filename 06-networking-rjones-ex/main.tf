provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_instance" "test1" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.apps-primary.id
  tags = {
    Name = "test"
    Application = "web-api"
  }
  security_groups = [aws_security_group.web-app-sg.id]
}