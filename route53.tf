resource "aws_route53_zone" "fes_main" {
  name = "nitncfes.net"
  tags = {
    Environment = "fes"
  }
}