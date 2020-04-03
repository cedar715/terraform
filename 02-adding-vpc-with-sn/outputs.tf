output "ips" {
  value = join(", ", aws_instance.web.*.private_ip)
}