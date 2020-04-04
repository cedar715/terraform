resource "aws_security_group" "alb" {
  name = "allow-http"
  vpc_id = aws_default_vpc.default.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      local.all_ips_cidr_block]
  }
  # Allow all outbound requests
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags = merge(local.tags, {
    Name = "allow-http"
  })
}

resource "aws_security_group" "allow_web" {
  name = "allow-web"
  vpc_id = aws_default_vpc.default.id
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = [
      local.all_ips_cidr_block]
  }
  tags = merge(local.tags, {
    Name = "allow-web"
  })
}