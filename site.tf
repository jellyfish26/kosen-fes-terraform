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
  cloudfront_headers = ["Origin"]
  domain = aws_route53_zone.fes_main
}

module "info3-site" {
  source = "./module/cloudfront"
  name = "3info"
  domain = aws_route53_zone.fes_main
}

module "dev-site" {
  source = "./module/cloudfront"
  name = "devsite"
  domain = aws_route53_zone.fes_main
}

module "cdn-site" {
  source = "./module/cloudfront"
  name = "cdn"
  accept_origin = ["https://site.nitncfes.net"]
  cloudfront_headers = ["Origin"]
  domain = aws_route53_zone.fes_main
}

module "math-site" {
  source = "./module/cloudfront"
  name = "mandelbrot"
  domain = aws_route53_zone.fes_main
}

module "lottery" {
  source = "./module/cloudfront"
  name = "lottery"
  domain = aws_route53_zone.fes_main
}