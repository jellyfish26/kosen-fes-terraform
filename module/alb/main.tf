resource "aws_security_group" "lb_sec" {
  name = "${var.name}-ld-sec"
  vpc_id = aws_vpc.vpc_main.id

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { 
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "alb_main" {
  name = "${var.name}-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.lb_sec.id]
  subnets = [
    aws_subnet.vpc_public1_subnet.id,
    aws_subnet.vpc_public2_subnet.id
  ]
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "${var.name}-tg"
  port     = "80"
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc_main.id
  depends_on = [aws_lb.alb_main]

  health_check {
    port = "80"
    path = "/ping"
  }

  stickiness {
    type = "lb_cookie"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb_main.arn

  certificate_arn = aws_acm_certificate.domain_certificate.arn
  port = "443"
  protocol = "HTTPS"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_lb_listener" "alb_redirect" {
  load_balancer_arn = aws_lb.alb_main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "alb_rule_https" {
  listener_arn = aws_lb_listener.alb_listener.arn

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}