variable "region" {
  type = string
  default = "us-east-1"
}

//us-east-1	 ubuntu bionic	18.04 LTS	amd64	hvm:ebs-ssd	20200323	ami-0a4f4704a9146742a	hvm
variable "ami" {
  type = string
  default = "ami-0a4f4704a9146742a"
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "instance_type" {
  default = "t2.micro"
}

variable "server_port" {
  default = 8080
}