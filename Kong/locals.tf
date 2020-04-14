locals {
  cidr_block_all = "0.0.0.0/0"
  ssh_port = 22
  kong_proxy_port = 8000
  kong_proxy_port_tls = 8443
  kong_admin_port = 8001
  kong_admin_port_tls = 8444
  open_web_ports = [
    local.kong_admin_port,
    local.kong_admin_port_tls,
    local.kong_proxy_port,
    local.kong_proxy_port_tls
  ]
}

