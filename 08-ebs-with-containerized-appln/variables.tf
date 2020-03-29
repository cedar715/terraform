variable "region" {
  default = "us-east-1"
}
variable "aws_access_key" {
}
variable "aws_secret_key" {
}
variable "ami" {
  default = "ami-0fc61db8544a617ed"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "path_to_public_key" {
  default = "tfkey.pub"
}

variable "path_to_pvt_key" {
  default = "tfkey"
}

variable "key_name" {
  default = "tfkey"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}
variable "tier2_sn_cidr_block" {
  default = "10.0.1.0/24"
}
variable "tier3_sn_cidr_block" {
  default = "10.0.2.0/24"
}

variable "snapshot_id" {
  default = ""
}