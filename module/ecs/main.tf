resource "aws_ecs_cluster" "ecs_app" {
  name = "${var.ecs_name}-cluster"
}

data "aws_iam_policy_document" "ecs_iam_s3" {
  statement {
    sid = "1"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject"
    ]

    resources = ["arn:aws:s3::*"]
  }
}

data "aws_iam_policy_document" "ecs_iam_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ecs_iam_policy" {
  name        = "ecs-policy-${var.ecs_name}"
  policy      = data.aws_iam_policy_document.ecs_iam_s3.json
}

resource "aws_iam_role" "ecs_iam" {
  name = "ecs-role-${var.ecs_name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_iam_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_iam_attachment" {
  role = aws_iam_role.ecs_iam.name
  policy_arn = aws_iam_policy.ecs_iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs-exec-attachment" {
  role = aws_iam_role.ecs_iam.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "ecs_task" {
  family = "${var.ecs_name}-task-definition"
  cpu = var.cpu
  memory = var.memory
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"] 
  execution_role_arn = aws_iam_role.ecs_iam.arn
  container_definitions = <<TASK_DEFINITION
[
  {
    "name": "${var.ecs_name}-http",
    "image": "${var.account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${var.ecs_name}:latest",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
TASK_DEFINITION
}

resource "aws_security_group" "ecs_sec" {
  name = "${var.ecs_name}-sec"
  vpc_id = var.vpc_main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.vpc_main.cidr_block]
  }

  egress { 
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "ecs_service" {
  name = "${var.ecs_name}-service"
  cluster = aws_ecs_cluster.ecs_app.arn
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count = var.desired_count
  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = var.load_balancer.arn
    container_name = "${var.ecs_name}-http"
    container_port = 80
  }

  network_configuration {
    security_groups = [aws_security_group.ecs_sec.id]
    subnets = [var.vpc_private_main_subnet.id, var.vpc_private_sub_subnet.id]
  }
}