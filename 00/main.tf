provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_instance" "ubuntu" {
  ami = var.ubuntu_ami
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.allow_ssh_web.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Jai Ganesh! Hello, World" > index.html
              nohop busybox httpd -f -p 8080 &
              EOF

  tags = {
    Name = "My-First-Instance-Created-From-TF"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key = file(var.pvt_key_path)

  }

}

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "allow_ssh_web" {
  name = "ubuntu-ssh-web-sg"
  vpc_id = aws_default_vpc.default.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
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