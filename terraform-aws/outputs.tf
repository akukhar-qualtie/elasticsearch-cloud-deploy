output "clients_dns" {
  value = aws_lb.elasticsearch-alb.*.dns_name
}

output "clients_alb_arn" {
  value = aws_lb.elasticsearch-alb.*.arn
}

output "clients_alb_zone_id" {
  value = aws_lb.elasticsearch-alb.*.zone_id
}

output "clients_sg_id" {
  value = aws_security_group.elasticsearch_clients_security_group.*.id[0]
}

output "vm_password" {
  value = random_string.vm-login-password.result
}
