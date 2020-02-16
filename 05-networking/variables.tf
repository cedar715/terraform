variable "aws_access_key" {
}
variable "aws_secret_key" {
}
variable "region" {
  default = "ap-south-1"
}
variable "pvt_key_path" {
}
variable "key_name" {
}

variable "instance_type" {
  default = "t2.micro"
}
variable "ubuntu_ami" {
  default = "ami-0620d12a9cf777c87"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "load-balancing-a-cidr" {
  default = "10.0.0.0/24"
}
variable "applications-a" {
  default = "10.0.1.0/24"
}