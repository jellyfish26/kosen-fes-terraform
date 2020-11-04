module "clicker-site" {
  source = "./module/cloudfront"
  name = "clicker"
  domain = aws_route53_zone.fes_main
}

module "reversi-site" {
  source = "./module/cloudfront"
  name = "reversi"
  domain = aws_route53_zone.fes_main
}

module "main-site" {
  source = "./module/cloudfront"
  name = "site"
  domain = aws_route53_zone.fes_main
}

module "info3-site" {
  source = "./module/cloudfront"
  name = "3info"
  accept_ip = ["202.24.240.0/21", "160.86.219.12/32"]
  domain = aws_route53_zone.fes_main
}

module "dev-site" {
  source = "./module/cloudfront"
  name = "devsite"
  accept_ip = ["202.24.240.0/21", "160.86.219.12/32"]
  domain = aws_route53_zone.fes_main
}

module "cdn-site" {
  source = "./module/cloudfront"
  name = "cdn"
  accept_ip = ["202.24.240.0/21", "160.86.219.12/32"]
  accept_origin = ["https://devsite.nitncfes.net", "https://site.nitncfes.net"]
  domain = aws_route53_zone.fes_main
}

module "math-site" {
  source = "./module/cloudfront"
  name = "mandelbrot"
  accept_ip = ["202.24.240.0/21", "160.86.219.12/32"]
  domain = aws_route53_zone.fes_main
}