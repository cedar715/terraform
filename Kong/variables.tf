variable "region" {
  default = "us-east-1"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "ami" {
  default = "ami-0323c3dd2da7fb37d"
}
variable "instance_type" {
  default = "t2.micro"
}

variable "path_to_pub_key" {}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}
variable "tier1_1_sn_cidr_block" {
  default = "10.0.1.0/24"
}
variable "tier1_2_sn_cidr_block" {
  default = "10.0.2.0/24"
}

variable "tier2_1_sn_cidr_block" {
  default = "10.0.3.0/24"
}
variable "tier2_2_sn_cidr_block" {
  default = "10.0.4.0/24"
}