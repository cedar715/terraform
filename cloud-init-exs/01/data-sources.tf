data "aws_availability_zones" "available" {}

// other option to get default VPC
// resource "aws_default_vpc" "default" {}
data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnets" {
  vpc_id = data.aws_vpc.default_vpc.id
}