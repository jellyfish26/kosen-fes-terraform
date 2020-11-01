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