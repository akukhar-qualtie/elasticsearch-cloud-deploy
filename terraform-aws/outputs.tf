output "clients_dns" {
  value = aws_lb.elasticsearch-alb.*.dns_name
}

output "clients_alb_zone_id" {
  value = aws_lb.elasticsearch-alb.*.zone_id
}

output "vm_password" {
  value = random_string.vm-login-password.result
}
