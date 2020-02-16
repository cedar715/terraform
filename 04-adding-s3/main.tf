/*

My first tf infra deploy CONFIGURATION file

HIGHLEVEL STEPS:

#1 define variables to store AWS creds
#2 define provider
#3 define data source to pull the info of the resources present in the provider
#4 define the resource that needs to be provisioned
#5 define the output

*/

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  # var is a keyword in HCL
  # every provider block has some sort of credentials to access the provider, the region to deploy the resources
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
  version = "~> 2.0"
}

##################################################################################
# LOCALS
##################################################################################

locals {
  common_tags = {
    billingCode = var.billing_code_tag
    environment = var.environment_tag
  }
  s3_bucket_name = "${var.bucket_name_prefix}-${var.environment_tag}-${random_integer.randInt.result}"
}


##################################################################################
# DATA - pull data outside of config file. Here we are getting from provider itself
##################################################################################
data "aws_ami" "aws-linux" {
  most_recent = true
  owners = [
    "amazon"]

  filter {
    name = "name"
    values = [
      "amzn-ami-hvm*"]
  }

  filter {
    name = "root-device-type"
    values = [
      "ebs"]
  }
  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }
}

data "aws_availability_zones" "available" {}

##################################################################################
# RESOURCES THAT WILL BE PROVISIONED IN THE CLOUD
##################################################################################

resource "random_integer" "randInt" {
  max = 99999
  min = 10000
}

## NETWORKING
resource "aws_vpc" "vpc" {
  cidr_block = var.network_address_space

  tags = merge(local.common_tags, {
    name = "${var.environment_tag}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    name = "${var.environment_tag}-igw"
  })
}

resource "aws_subnet" "subnet1" {
  cidr_block = var.subnet1_address_space
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  # returns multiple
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = merge(local.common_tags, {
    Name = "${var.environment_tag}-subnet1"
  })

}

resource "aws_subnet" "subnet2" {
  cidr_block = var.subnet2_address_space
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = merge(local.common_tags, {
    Name = "${var.environment_tag}-subnet2"
  })

}

## ROUTING
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.common_tags, {
    Name = "${var.environment_tag}-rtb"
  })

}

resource "aws_route_table_association" "rta-subnet1" {
  route_table_id = aws_route_table.rtb.id
  subnet_id = aws_subnet.subnet1.id
}

resource "aws_route_table_association" "rta-subnet2" {
  route_table_id = aws_route_table.rtb.id
  subnet_id = aws_subnet.subnet2.id
}

# SECURITY GROUPS
resource "aws_security_group" "nginx_sg" {
  name = "nginx_sg"
  vpc_id = aws_vpc.vpc.id

  #SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  #HTTP access from VPC
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      var.network_address_space]
  }

  #outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_tag}-nginx"
  })

}

resource "aws_security_group" "elb-sg" {
  name = "nginx-elb-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_tag}-elb"
  })

}

resource "aws_elb" "web" {
  name = "nginx-elb"
  subnets = [
    aws_subnet.subnet1.id,
    aws_subnet.subnet2.id]
  security_groups = [
    aws_security_group.elb-sg.id]
  instances = [
    aws_instance.nginx1.id,
    aws_instance.nginx2.id]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_tag}-elb"
  })

}

# provision of new EC2 instance
resource "aws_instance" "nginx1" {
  /*
  AMI retrieved from Data Source. Instead of retrieving dynamically,
  it can be hardcoded like instance_type.
  */
  ami = data.aws_ami.aws-linux.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet1.id
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.nginx_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.nginx_profile.name


  connection {
    #define conn block inside resource for allowing ssh
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    # pvt key that will be used for SSH conn
    private_key = file(var.private_key_path)
  }

  # configuration to be used by s3cmd. s3cmd is used to copy files to & fro from ec2 instance.
  provisioner "file" {
    content = <<EOF
access_key =
secret_key =
security_token =
use_https = True
bucket_location = US

EOF
    destination = "/home/ec2-user/.s3cfg"
  }

  # copy the rotated nginx logs to S3
  provisioner "file" {
    #heredoc syntax
    content = <<EOF
/var/log/nginx/*log {
    daily
    rotate 10
    missingok
    compress
    sharedscripts
    postrotate
    endscript
    lastaction
        INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id`
        sudo /usr/local/bin/s3cmd sync --config=/home/ec2-user/.s3cfg /var/log/nginx/ s3://${aws_s3_bucket.web_bucket.id}/nginx/$INSTANCE_ID/
    endscript
}
EOF
    destination = "/home/ec2-user/nginx"
  }

  # scripts to run when resources are created/destroyed
  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "sudo cp /home/ec2-user/.s3cfg /root/.s3cfg",
      "sudo cp /home/ec2-user/nginx /etc/logrotate.d/nginx",
      "sudo pip install s3cmd",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/index.html .",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/Globo_logo_Vert.png .",
      "sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html",
      "sudo cp /home/ec2-user/Globo_logo_Vert.png /usr/share/nginx/html/Globo_logo_Vert.png",
      "sudo logrotate -f /etc/logrotate.conf"
    ]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_tag}-nginx1"
  })

}

resource "aws_instance" "nginx2" {
  /*
  AMI retrieved from Data Source. Instead of retrieving dynamically,
  it can be hardcoded like instance_type.
  */
  ami = data.aws_ami.aws-linux.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet2.id
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.nginx_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.nginx_profile.name


  connection {
    #define conn block inside resource for allowing ssh
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    # pvt key that will be used for SSH conn
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    content = <<EOF
access_key =
secret_key =
security_token =
use_https = True
bucket_location = US

EOF
    destination = "/home/ec2-user/.s3cfg"
  }

  provisioner "file" {
    content = <<EOF
/var/log/nginx/*log {
    daily
    rotate 10
    missingok
    compress
    sharedscripts
    postrotate
    endscript
    lastaction
        INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id`
        sudo /usr/local/bin/s3cmd sync --config=/home/ec2-user/.s3cfg /var/log/nginx/ s3://${aws_s3_bucket.web_bucket.id}/nginx/$INSTANCE_ID/
    endscript
}

EOF
    destination = "/home/ec2-user/nginx"
  }

  # scripts to run when resources are created/destroyed
  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "sudo cp /home/ec2-user/.s3cfg /root/.s3cfg",
      "sudo cp /home/ec2-user/nginx /etc/logrotate.d/nginx",
      "sudo pip install s3cmd",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/index.html .",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/Globo_logo_Vert.png .",
      "sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html",
      "sudo cp /home/ec2-user/Globo_logo_Vert.png /usr/share/nginx/html/Globo_logo_Vert.png",
      "sudo logrotate -f /etc/logrotate.conf"

    ]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_tag}-nginx2"
  })

}

# S3 Bucket config#
resource "aws_iam_role" "allow_nginx_s3" {
  name = "allow_nginx_s3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "nginx_profile" {
  name = "nginx_profile"
  role = aws_iam_role.allow_nginx_s3.name
}

resource "aws_iam_role_policy" "allow_s3_all" {
  name = "allow_s3_all"
  role = aws_iam_role.allow_nginx_s3.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
                "arn:aws:s3:::${local.s3_bucket_name}",
                "arn:aws:s3:::${local.s3_bucket_name}/*"
            ]
    }
  ]
}
EOF

}

resource "aws_s3_bucket" "web_bucket" {
  bucket = local.s3_bucket_name
  acl = "private"
  # not public s3 bucket
  force_destroy = true
  # => TF can destroy this bucket even if its not empty

  tags = merge(local.common_tags, {
    Name = "${var.environment_tag}-web-bucket"
  })

}

resource "aws_s3_bucket_object" "website" {
  bucket = aws_s3_bucket.web_bucket.bucket
  key = "/website/index.html"
  source = "./index.html"

}

resource "aws_s3_bucket_object" "graphic" {
  #upload to this bucket
  bucket = aws_s3_bucket.web_bucket.bucket
  # the s3 bucket key with which the file should be stored
  key = "/website/Globo_logo_Vert.png"
  source = "./Globo_logo_Vert.png"

}
