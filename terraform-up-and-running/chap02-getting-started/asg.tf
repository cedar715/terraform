resource "aws_launch_configuration" "test_instance_asg_lc" {
  image_id = var.ami
  instance_type = var.instance_type
  security_groups = [
    aws_security_group.allow_web.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello Sai (ASG) !!" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "test_instance_asg" {
  max_size = 10
  min_size = 2

  # either of the one needs to be specified
  //availability_zones = data.aws_availability_zones.available.names
  vpc_zone_identifier = data.aws_subnet_ids.default_subnets.ids

  # NOT ID, but name
  launch_configuration = aws_launch_configuration.test_instance_asg_lc.name

  target_group_arns = [
    aws_lb_target_group.asg.arn]

  # default is EC2
  health_check_type = "ELB"

  # tag NOT tags
  tag {
    key = "Name"
    propagate_at_launch = true
    value = "ASG Property"
  }
}