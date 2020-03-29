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
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_web.id]

  # to alter the default storage or type of the root volume
  root_block_device {
    delete_on_termination = true
    volume_type = "gp2"
    volume_size = 16
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.path_to_pvt_key)
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo usermod -aG docker ec2-user"
    ]
  }

}

resource "aws_ebs_volume" "data_vol" {
  availability_zone = aws_instance.test-instance.availability_zone
  size = 20
  type = "gp2"
  tags = {
    Name = "Data Vol"
    ManagedBy = "TF"
  }
}

//resource "aws_ebs_volume" "from_snapshot" {
//  snapshot_id = var.snapshot_id
//  availability_zone = aws_instance.test-instance.availability_zone
//  tags = {
//    Name = "Vol from Snapshot"
//    ManagedBy = "TF"
//  }
//}

resource "aws_volume_attachment" "data_vol_attachment" {
  device_name = "/dev/xvdf"
  instance_id = aws_instance.test-instance.id
  volume_id = aws_ebs_volume.data_vol.id
}