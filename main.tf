

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
  family       = "platform-training-ecs-task"
  network_mode = "awsvpc"
  container_definitions = jsonencode([
    {
      "name" : "platform-training-app",
      "image" : var.platform_image
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