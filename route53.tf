resource "aws_route53_zone" "fes_main" {
  name = "nara-k.fes"
  tags = {
    Environment = "fes"
  }
}