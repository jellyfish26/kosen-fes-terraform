output "target_group" {
  value = aws_lb_target_group.alb_tg
}

output "vpc" {
  value = aws_vpc.vpc_main
}

output "vpc_public_main_subnet" {
  value = aws_subnet.vpc_public1_subnet
}

output "vpc_public_sub_subnet" {
  value = aws_subnet.vpc_public2_subnet
}

output "vpc_private_main_subnet" {
  value = aws_subnet.vpc_private1_subnet
}

output "vpc_private_sub_subnet" {
  value = aws_subnet.vpc_private2_subnet
}