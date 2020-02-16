##################################################################################
# VARIABLES
##################################################################################
variable "aws_secret_key" {
  type = string
  description = "secret key to access AWS provider"
}
variable "aws_access_key" {
  type = string
  description = "access key to talk to provider(AWS)"
}
variable "private_key_path" {
  description = "path to the private key in your local instance to connect to AWS instance. This shd correspond to the key pair that's in AWS."
}
variable "key_name" {
  description = "key pair that exists in AWS"
}
variable "region" {
  default = "ap-south-1"
  description = "region to deploy the resources"
}

variable "network_address_space" {
  default = "10.1.0.0/16"
}

variable "subnet1_address_space" {
  default = "10.1.0.0/24"
}

variable "subnet2_address_space" {
  default = "10.1.1.0/24"
}

variable "bucket_name_prefix" {}
variable "environment_tag" {}
variable "billing_code_tag" {}