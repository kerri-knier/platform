

provider "aws" {
  region = "eu-west-2"
}

resource "aws_ecr_repository" "aws_ecr" {
  name                 = "platform-training-kerginx"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "aws_ecs" {
  name = "platform-training-cluster"
}

variable "platform_image" {
  type     = string
  nullable = false
}

resource "aws_ecs_task_definition" "aws_ecs_task" {
  family             = "platform-training-ecs-task"
  network_mode       = "awsvpc"
  execution_role_arn = "arn:aws:iam::586634938182:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
  container_definitions = jsonencode([
    {
      "name" : "platform-training-app",
      "image" : "586634938182.dkr.ecr.eu-west-2.amazonaws.com/platform-training-kerginx:fc64b265c8303e7bba01976a626e81978fb64dbf",
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort" : 80,
          "protocol" : "tcp",
        }
      ],
      "essential" : true,
    }
  ])
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

data "aws_subnets" "default_subnet" {
  filter {
    name   = "vpc-id"
    values = ["vpc-06db0118879aa0ecd"]
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = "platform-training-ecs-service"
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.aws_ecs.id
  task_definition = aws_ecs_task_definition.aws_ecs_task.arn
  desired_count   = 1

  network_configuration {
    subnets = data.aws_subnets.default_subnet.ids
  }
}
