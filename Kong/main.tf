provider "aws" {
  region = var.region
  secret_key = var.aws_secret_key
  access_key = var.aws_access_key
}

resource "aws_key_pair" "ssh_key" {
  public_key = file(var.path_to_pub_key)
}