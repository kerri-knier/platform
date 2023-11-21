

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
  execution_role_arn = "arn:aws:iam::586634938182:role/ecsTaskExecutionRole"
  container_definitions = jsonencode([
    {
      "name" : "platform-training-app",
      "image" : var.platform_image,
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort" : 80,
          "protocol" : "tcp",
          "appProtocol" : "http",
        }
      ],
      "essential" : true,
    }
  ])
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

data "aws_security_groups" "vpc_security_groups" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = "platform-training-ecs-service"
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.aws_ecs.id
  task_definition = aws_ecs_task_definition.aws_ecs_task.arn
  desired_count   = 1

  network_configuration {
    security_groups  = data.aws_security_groups.vpc_security_groups.ids
    subnets          = data.aws_subnets.default_subnet.ids
    # assign_public_ip = true
  }
}

# resource "aws_ecs_cluster_capacity_providers" "aws_capacity_provider" {
#   cluster_name = aws_ecs_cluster.aws_ecs.name

#   capacity_providers = ["FARGATE"]

#   default_capacity_provider_strategy {
#     base              = 1
#     weight            = 100
#     capacity_provider = "FARGATE"
#   }
# }