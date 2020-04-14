resource "aws_security_group" "allow_ssh_web" {
  name = "allow-ssh-web"
  vpc_id = data.aws_vpc.default_vpc.id

  tags = merge(local.tags, {
    Name = "allow-web"
  })
}

locals {
  open_ports = [
    80,
    22]
}

resource "aws_security_group_rule" "allow_all_outboud" {
  from_port = 0
  to_port = 0
  protocol = "-1"
  type = "egress"
  cidr_blocks = [
    "0.0.0.0/0"]
  security_group_id = aws_security_group.allow_ssh_web.id
}

resource "aws_security_group_rule" "ingress_http" {
  count = length(local.open_ports)

  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"]
  from_port = element(local.open_ports, count.index)
  to_port = element(local.open_ports, count.index)

  security_group_id = aws_security_group.allow_ssh_web.id
}