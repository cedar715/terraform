resource "aws_security_group" "allow_web" {
  vpc_id = aws_vpc.my_vpc.id
  name = "allow_web"
  description = "Allow Web traffic"
}

resource "aws_security_group_rule" "ingress" {
  count = length(local.open_web_ports)

  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    local.cidr_block_all]
  from_port = element(local.open_web_ports, count.index)
  to_port = element(local.open_web_ports, count.index)

  security_group_id = aws_security_group.allow_web.id
}

resource "aws_security_group_rule" "egress" {

  type = "egress"
  protocol = "-1"
  cidr_blocks = [
    local.cidr_block_all]
  from_port = 0
  to_port = 0

  security_group_id = aws_security_group.allow_web.id
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH traffic"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port = local.ssh_port
    to_port = local.ssh_port
    protocol = "tcp"
    cidr_blocks = [
      local.cidr_block_all]
  }

  #outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}