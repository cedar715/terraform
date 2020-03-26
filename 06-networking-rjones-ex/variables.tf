variable "aws_access_key" {
}
variable "aws_secret_key" {
}
variable "region" {
  default = "us-east-1"
}
//variable "pvt_key_path" {
//}
//variable "key_name" {
//}

variable "instance_type" {
  default = "t2.micro"
}
variable "ami" {
  default = "ami-0fc61db8544a617ed"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "load-balancing-a-cidr" {
  # subrange of VPC's CIDR block
  default = "10.0.0.0/24"

}
variable "applications-a" {
  default = "10.0.1.0/24"
}