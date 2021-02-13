resource "aws_route53_record" "elk" {
  name    = var.elk_subdomain
  type    = "A"
  zone_id = var.zone_id

  alias {
    name                   = aws_lb.elasticsearch-alb.dns_name
    zone_id                = aws_lb.elasticsearch-alb.zone_id
    evaluate_target_health = true
  }
}

