data "template_file" "init_script" {
  template = file("files/cloud-init.yml")
}

data "template_cloudinit_config" "cloudinit_config" {
  gzip = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = data.template_file.init_script.rendered
  }
}

