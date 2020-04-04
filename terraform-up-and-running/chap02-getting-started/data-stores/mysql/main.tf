provider "aws" {
  region = var.region
  secret_key = var.aws_secret_key
  access_key = var.aws_access_key
  version = "~> 2.56"
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "example_database"
  username = "admin"

  password = var.db_password
}