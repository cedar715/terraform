variable "region" {
  type = string
}

variable "ami" {
  type = string
}

variable "vpc_cidr_block" {
  default = "192.168.100.0/24"
}

variable "azs" {
  type = list(string)
}

variable "aws_secret_key" {
  type = string
}
variable "aws_access_key" {
  type = string
}

variable instance_count {
  default = 2
}
