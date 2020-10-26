resource "aws_s3_bucket" "site" {
  bucket = "${var.name}-site-static"
  acl = "private"

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

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.id.cloudfront_access_identity_path
    }
  }

  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket = aws_s3_bucket.log.bucket_domain_name
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

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
}

resource "aws_route53_record" "sub_cname" {
  type = "CNAME"

  name = "${var.name}.nitncfes.net"
  zone_id = var.domain.id

  ttl = 300
  records = [aws_cloudfront_distribution.s3_distribution.domain_name] 
}