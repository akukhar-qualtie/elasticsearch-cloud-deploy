resource "aws_security_group" "elasticsearch-alb-sg" {
  name        = "${var.es_cluster}-alb-sg"
  description = "ElasticSearch Ports for ALB Access"
  vpc_id      = var.vpc_id

  # allow http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow https
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow Kibana port access
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow Cerebro port access
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow Grafana port access
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow ElasticSearch port access
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Target Groups
#-----------------------------------------------------

resource "aws_lb_target_group" "esearch-p9200-tg" {
  name     = "${var.es_cluster}-p9200-tg"
  port     = 9200
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/"
    port                = 9200
    interval            = 15
    matcher             = "401"
  }
}

resource "aws_lb_target_group" "kibana-p5601-tg" {
  name     = "${var.es_cluster}-p5601-tg"
  port     = 5601
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/"
    port                = 5601
    interval            = 15
    matcher             = "302"
  }
}

resource "aws_lb_target_group" "grafana-p3000-tg" {
  name     = "${var.es_cluster}-p3000-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/"
    port                = 3000
    interval            = 15
    matcher             = "302"
  }
}

resource "aws_lb_target_group" "cerebro-p9000-tg" {
  name     = "${var.es_cluster}-p9000-tg"
  port     = 9000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/"
    port                = 9000
    interval            = 15
    matcher             = "303"
  }
}

resource "aws_lb" "elasticsearch-alb" {
  name               = "${var.es_cluster}-alb"
  internal           = !var.public_facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elasticsearch-alb-sg.id]
  subnets            = coalescelist(var.alb_subnets, tolist(data.aws_subnet_ids.all-subnets.ids))

  enable_deletion_protection = false
}

#-----------------------------------------------------

# ALB Listeners and Listener Rules
#-----------------------------------------------------

resource "aws_lb_listener" "redirect" {
  load_balancer_arn = aws_lb.elasticsearch-alb.arn
  protocol          = "HTTP"
  port              = 80
  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "esearch-https" {
  load_balancer_arn = aws_lb.elasticsearch-alb.arn
  protocol          = "HTTPS"
  port              = 443
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.domain_cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kibana-p5601-tg.arn
  }
}

#resource "aws_lb_listener_rule" "kibana" {
#  listener_arn = aws_lb_listener.esearch-https.arn
#  priority     = 10
#  action {
#    type = "redirect"
#    redirect {
#      port        = 5601
#      protocol    = "HTTPS"
#      status_code = "HTTP_301"
#      host        = aws_route53_record.elk.fqdn
#      path        = "/"
#    }
#  }
#  condition {
#    path_pattern {
#      values = ["/kibana"]
#    }
#  }
#}

resource "aws_lb_listener" "esearch" {
  load_balancer_arn = aws_lb.elasticsearch-alb.arn
  protocol          = "HTTPS"
  port              = 9200
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.domain_cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.esearch-p9200-tg.arn
  }
}

resource "aws_lb_listener" "kibana" {
  load_balancer_arn = aws_lb.elasticsearch-alb.arn
  port              = 5601
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.domain_cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kibana-p5601-tg.arn
  }
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.elasticsearch-alb.arn
  port              = 3000
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.domain_cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana-p3000-tg.arn
  }
}

resource "aws_lb_listener" "cerebro" {
  load_balancer_arn = aws_lb.elasticsearch-alb.arn
  port              = 9000
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.domain_cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cerebro-p9000-tg.arn
  }
}

