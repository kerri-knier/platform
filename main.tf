

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

data "aws_iam_policy_document" "ecs_exec_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "sssmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecs_exec" {
  name               = "ecs_exec_role"
  path               = "/system"
  assume_role_policy = data.aws_iam_policy_document.ecs_exec_policy.json
}

resource "aws_ecs_task_definition" "aws_ecs_task" {
  family             = "platform-training-ecs-task"
  network_mode       = "awsvpc"
  task_role_arn      = aws_iam_role.ecs_exec.arn
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
  # Remember to avoid leaving this running!
  desired_count = 3
  # allow commands to be executed via aws cli
  enable_execute_command = true

  network_configuration {
    security_groups  = data.aws_security_groups.vpc_security_groups.ids
    subnets          = data.aws_subnets.default_subnet.ids
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity       = 1
  max_capacity       = 4
  resource_id        = "service/${aws_ecs_cluster.aws_ecs.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_scaling" {
  name               = "platform-training-ecs-autoscale-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
