module "clicker-site" {
  source = "./module/cloudfront"
  name = "clicker"
  domain = aws_route53_zone.fes_main
}