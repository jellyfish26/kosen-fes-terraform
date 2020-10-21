resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.${var.base_ip}.0/22"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}

resource "aws_internet_gateway" "vpc_gw" {
  vpc_id = aws_vpc.vpc_main.id
}

resource "aws_subnet" "vpc_public1_subnet" {
  vpc_id = aws_vpc.vpc_main.id
  cidr_block = "10.0.${var.base_ip}.0/24"
  availability_zone = "ap-northeast-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public1"
  }
}

resource "aws_subnet" "vpc_public2_subnet" {
  vpc_id = aws_vpc.vpc_main.id
  cidr_block = "10.0.${var.base_ip + 1}.0/24"
  availability_zone = "ap-northeast-1c"

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public2"
  }
}

resource "aws_subnet" "vpc_private1_subnet" {
  vpc_id = aws_vpc.vpc_main.id
  cidr_block = "10.0.${var.base_ip + 2}.0/24"
  availability_zone = "ap-northeast-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-private1"
  }
}

resource "aws_subnet" "vpc_private2_subnet" {
  vpc_id = aws_vpc.vpc_main.id
  cidr_block = "10.0.${var.base_ip + 3}.0/24"
  availability_zone = "ap-northeast-1c"

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-private2"
  }
}

resource "aws_eip" "eip_main" {
  vpc = true
}

resource "aws_eip" "eip_sub" {
  vpc = true
}

resource "aws_nat_gateway" "vpc_nat_main" {
  subnet_id = aws_subnet.vpc_public1_subnet.id
  allocation_id = aws_eip.eip_main.id

  tags = {
    Name = "${var.name}-gw-main"
  }
}

resource "aws_nat_gateway" "vpc_nat_sub" {
  subnet_id = aws_subnet.vpc_public2_subnet.id
  allocation_id = aws_eip.eip_sub.id

  tags = {
    Name = "${var.name}-gw-sub"
  }
}

resource "aws_route_table" "vpc_table" {
  vpc_id = aws_vpc.vpc_main.id
}

resource "aws_route" "vpc_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.vpc_table.id
  gateway_id = aws_internet_gateway.vpc_gw.id
}

resource "aws_route_table_association" "vpc_main_ac" {
  subnet_id = aws_subnet.vpc_public1_subnet.id
  route_table_id = aws_route_table.vpc_table.id
}

resource "aws_route_table_association" "vpc_sub_ac" {
  subnet_id = aws_subnet.vpc_public2_subnet.id
  route_table_id = aws_route_table.vpc_table.id
}

resource "aws_route_table" "vpc_private1_table" {
  vpc_id = aws_vpc.vpc_main.id
}

resource "aws_route_table" "vpc_private2_table" {
  vpc_id = aws_vpc.vpc_main.id
}

resource "aws_route" "vpc_private1_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.vpc_private1_table.id
  nat_gateway_id = aws_nat_gateway.vpc_nat_main.id
}

resource "aws_route" "vpc_private2_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.vpc_private2_table.id
  nat_gateway_id = aws_nat_gateway.vpc_nat_sub.id
}

resource "aws_route_table_association" "vpc_private1_ac" {
  subnet_id = aws_subnet.vpc_private1_subnet.id
  route_table_id = aws_route_table.vpc_private1_table.id
}

resource "aws_route_table_association" "vpc_private2_ac" {
  subnet_id = aws_subnet.vpc_private2_subnet.id
  route_table_id = aws_route_table.vpc_private2_table.id
}

resource "aws_security_group" "lb_sec" {
  name = "${var.name}-ld-sec"
  vpc_id = aws_vpc.vpc_main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { 
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "alb_main" {
  name = "${var.name}-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.lb_sec.id]
  subnets = [
    aws_subnet.vpc_public1_subnet.id,
    aws_subnet.vpc_public2_subnet.id
  ]
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "${var.name}-tg"
  port     = "80"
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc_main.id

  health_check {
    port = "80"
    path = "/ping"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb_main.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_lb_listener_rule" "alb_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}