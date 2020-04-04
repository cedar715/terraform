resource "aws_lb" "example" {
  subnets = data.aws_subnet_ids.default_subnets.ids
  load_balancer_type = "application"
  name = "terraform-lb"
  security_groups = [
    aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Sorry, your page is NOT found"
      status_code = 404
    }
  }
}

resource "aws_lb_target_group" "asg" {
  name = "tf-asg-ex"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  condition {
    field = "path-pattern"
    values = [
      "*"]
  }
}