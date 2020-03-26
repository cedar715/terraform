provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_key_pair" "ssh_keys" {
  key_name = var.key_name
  public_key = file(var.path_to_public_key)
}

resource "aws_instance" "test-instance" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = aws_key_pair.ssh_keys.id
  subnet_id = aws_subnet.tier2_sn.id
  security_groups = [
    aws_security_group.allow_ssh.id]
}

resource "aws_ebs_volume" "data_vol" {
  availability_zone = aws_instance.test-instance.availability_zone
  size = 20
  type = "gp2"
}

resource "aws_volume_attachment" "data_vol_attachment" {
  device_name = "/dev/xvdf"
  instance_id = aws_instance.test-instance.id
  volume_id = aws_ebs_volume.data_vol.id
}