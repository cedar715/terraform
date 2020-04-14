resource "aws_lb" "kong_alb" {
  subnets = [
    aws_subnet.tier1_1_sn_pub.id,
    aws_subnet.tier1_2_sn_pub.id]
  load_balancer_type = "application"
  name = "kong"
  security_groups = [
    aws_security_group.allow_web.id]
}

resource "aws_lb_listener" "kong_proxy_plain" {
  load_balancer_arn = aws_lb.kong_alb.arn
  port = local.kong_proxy_port
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Sorry, your page is NOT found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "kong_proxy_plain" {
  listener_arn = aws_lb_listener.kong_proxy_plain.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.kong_proxy_tg.arn
  }
  condition {
    field = "path-pattern"
    values = [
      "*"]
  }
}

resource "aws_lb_listener" "kong_admin_plain" {
  load_balancer_arn = aws_lb.kong_alb.arn
  port = local.kong_admin_port
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Sorry, your page is NOT found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "kong_admin_plain" {
  listener_arn = aws_lb_listener.kong_admin_plain.arn
  priority = 110
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.kong_admin_tg.arn
  }
  condition {
    field = "path-pattern"
    values = [
      "*"]
  }
}

resource "aws_lb_target_group" "kong_admin_tg" {
  name = "kong-admin-tg"
  port = local.kong_admin_port
  protocol = "HTTP"
  vpc_id = aws_vpc.my_vpc.id

  health_check {
    path = "/status"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "kong_proxy_tg" {
  name = "kong-proxy-tg"
  port = local.kong_proxy_port
  protocol = "HTTP"
  vpc_id = aws_vpc.my_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "404"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}