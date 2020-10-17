resource "aws_ecr_repository" "reversi_back" {
  name = "reversi-back"

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

resource "aws_ecr_repository" "clicker_back" {
  name = "clicker-back"

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "alb-reversi" {
  source = "./module/alb"
  name = "reversi-back"
  s3_bucket = aws_s3_bucket.reversi_back_state
}

module "ecs-reversi" {
  source = "./module/ecs"
  ecs_name = "reversi-back"
  account_id = data.aws_caller_identity.self.account_id
  cpu = "512"
  memory = "1024"
  depends_on = [module.alb-reversi]
  desired_count = 1
  load_balancer = module.alb-reversi.target_group
  vpc_main = module.alb-reversi.vpc
  vpc_private_main_subnet = module.alb-reversi.vpc_private_main_subnet
  vpc_private_sub_subnet = module.alb-reversi.vpc_private_sub_subnet
}
