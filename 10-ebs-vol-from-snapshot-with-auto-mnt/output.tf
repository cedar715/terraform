output "public_dns_name" {
  value = aws_instance.test-instance.public_dns
}