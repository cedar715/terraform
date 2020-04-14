output "alb_dns" {
  value = aws_lb.kong_alb.dns_name
}