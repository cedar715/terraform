resource "aws_launch_configuration" "kong_asg_lc" {
  image_id = var.ami
  instance_type = var.instance_type
  security_groups = [
    aws_security_group.allow_web.id,
    aws_security_group.allow_ssh.id]

  key_name = aws_key_pair.ssh_key.key_name

  user_data = data.template_cloudinit_config.cloudinit_config.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kong_asg" {
  min_size = 2
  max_size = 4

  vpc_zone_identifier = [
    aws_subnet.tier1_1_sn_pub.id,
    aws_subnet.tier1_2_sn_pub.id]

  launch_configuration = aws_launch_configuration.kong_asg_lc.name

  target_group_arns = [
    aws_lb_target_group.kong_proxy_tg.arn,
    aws_lb_target_group.kong_admin_tg.arn]

  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "KongASG"
    propagate_at_launch = false
  }
}