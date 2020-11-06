resource "aws_s3_bucket" "site" {
  bucket = "${var.name}-site-static"
  acl = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = var.accept_origin
    max_age_seconds = 0
  }

  tags = {
    Name = "${var.name}-bucket"
  }
}

resource "aws_cloudfront_origin_access_identity" "id" {
  comment = "${var.name}-id"
}

data "aws_iam_policy_document" "site_policy" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.id.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_policy.json
}

resource "aws_s3_bucket" "log" {
  bucket = "${var.name}-site-log"
  acl = "private"

  tags = {
    Name = "${var.name}-bucket"
  }
}

locals { 
  s3_origin_id = "${var.name}Origin"
}

resource "aws_acm_certificate" "domain_certificate" {
  domain_name = "${var.name}.nitncfes.net"
  provider = aws.virginia

  validation_method = "DNS"
}

resource "aws_route53_record" "site_cer" {
  depends_on = [aws_acm_certificate.domain_certificate]

  zone_id = var.domain.zone_id

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
  provider = aws.virginia

  validation_record_fqdns = [aws_route53_record.site_cer["${var.name}.nitncfes.net"].fqdn]
}

resource "aws_wafv2_ip_set" "accept_ip" {
  name               = "${var.name}-ipwaf"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.accept_ip

  provider = aws.virginia
}

resource "aws_wafv2_web_acl" "ip_waf" {
  name        = "${var.name}-waf"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name = "accept-ip"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.accept_ip.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${var.name}-cloudfront-ip"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name = "${var.name}-cloudfront"
    sampled_requests_enabled   = false
  }

  provider = aws.virginia
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.id.cloudfront_access_identity_path
    }
  }

  enabled = true
  is_ipv6_enabled = false
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket = aws_s3_bucket.log.bucket_domain_name
    prefix = var.name
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      headers = var.cloudfront_headers

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 300
    max_ttl = 600
  }

  custom_error_response {
    error_code = 403
    response_code = 200
    response_page_path = "/404.html"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "${var.name}-site"
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn = aws_acm_certificate_validation.main.certificate_arn
    ssl_support_method = "sni-only"
  }

  aliases = ["${var.name}.nitncfes.net"]

  web_acl_id = aws_wafv2_web_acl.ip_waf.arn
}

resource "aws_route53_record" "sub_cname" {
  type = "CNAME"

  name = "${var.name}.nitncfes.net"
  zone_id = var.domain.id

  ttl = 300
  records = [aws_cloudfront_distribution.s3_distribution.domain_name] 
}