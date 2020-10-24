resource "aws_ecr_repository" "reversi_back" {
  name = "reversi-back"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "clicker_back" {
  name = "clicker-back"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "reveri_policy" {
  repository = aws_ecr_repository.reversi_back.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "clicker_policy" {
  repository = aws_ecr_repository.clicker_back.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

module "alb-reversi" {
  source = "./module/alb"
  name = "reversi-back"
  base_ip = 0
  s3_bucket = aws_s3_bucket.reversi_back_state
  domain = aws_route53_zone.fes_main
}

module "ecs-reversi" {
  source = "./module/ecs"
  ecs_name = "reversi-back"
  account_id = data.aws_caller_identity.self.account_id
  cpu = "2048"
  memory = "8192"
  depends_on = [module.alb-reversi]
  desired_count = 2
  load_balancer = module.alb-reversi.target_group
  vpc_main = module.alb-reversi.vpc
  vpc_private_main_subnet = module.alb-reversi.vpc_private_main_subnet
  vpc_private_sub_subnet = module.alb-reversi.vpc_private_sub_subnet
}

module "alb-clicker" {
  source = "./module/alb"
  name = "clicker-back"
  base_ip = 4
  s3_bucket = aws_s3_bucket.clicker_back_state
  domain = aws_route53_zone.fes_main
}

module "ecs-clicker" {
  source = "./module/ecs"
  ecs_name = "clicker-back"
  account_id = data.aws_caller_identity.self.account_id
  cpu = "2048"
  memory = "8192"
  depends_on = [module.alb-clicker]
  desired_count = 1
  load_balancer = module.alb-clicker.target_group
  vpc_main = module.alb-clicker.vpc
  vpc_private_main_subnet = module.alb-clicker.vpc_private_main_subnet
  vpc_private_sub_subnet = module.alb-clicker.vpc_private_sub_subnet
}
