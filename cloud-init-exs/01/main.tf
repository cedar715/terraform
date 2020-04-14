provider "aws" {
  secret_key = var.aws_secret_key
  access_key = var.aws_access_key
  region = "us-east-1"
}

resource "aws_key_pair" "ssh_key" {
  public_key = file(var.path_to_pub_key)
}

resource "aws_instance" "test_instance" {
  ami = "ami-0a4f4704a9146742a"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [
    aws_security_group.allow_ssh_web.id]

  user_data = file("files/cloud-init.yml")
}
