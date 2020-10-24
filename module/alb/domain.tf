resource "aws_acm_certificate" "domain_certificate" {
  domain_name = "${var.name}.nitncfes.net"

  validation_method = "DNS"
}

resource "aws_route53_record" "sub_record_cer" {
  depends_on = [aws_acm_certificate.domain_certificate]

  zone_id = var.domain.id

  ttl = 60

  for_each = {
    for dvo in aws_acm_certificate.domain_certificate.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.domain_certificate.arn

  validation_record_fqdns = [aws_route53_record.sub_record_cer["${var.name}.nitncfes.net"].fqdn]
}

resource "aws_route53_record" "sub_record" {
  type = "A"

  name = "${var.name}.nitncfes.net"
  zone_id = var.domain.id

  alias {
    name = aws_lb.alb_main.dns_name
    zone_id = aws_lb.alb_main.zone_id
    evaluate_target_health = true
  }
}