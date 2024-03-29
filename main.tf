

provider "aws" {
  alias  = "default"
  region = "eu-west-2"
}

provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

resource "aws_ecr_repository" "aws_ecr" {
  name                 = "platform-training-kerginx"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# resource "aws_ecs_cluster" "aws_ecs" {
#   name = "platform-training-cluster"
# }

# # this provides permissions for using aws ecs execute-command
# data "aws_iam_policy_document" "ecs_exec" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "ssmmessages:CreateControlChannel",
#       "ssmmessages:CreateDataChannel",
#       "ssmmessages:OpenControlChannel",
#       "ssmmessages:OpenDataChannel"
#     ]
#     resources = ["*"]
#   }
# }

# # For a given role, this resource is incompatible with using the aws_iam_role resource inline_policy argument.
# # When using that argument and this resource, both will attempt to manage the role's inline policies and
# # Terraform will show a permanent difference.
# resource "aws_iam_role_policy" "ecs_exec" {
#   name   = "ecs_exec_policy"
#   role   = aws_iam_role.ecs_exec.id
#   policy = data.aws_iam_policy_document.ecs_exec.json
# }

# data "aws_iam_policy_document" "ecs_task_execution" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "ecs_exec" {
#   name               = "ecs_exec_role"
#   path               = "/platformtraining/"
#   assume_role_policy = data.aws_iam_policy_document.ecs_task_execution.json
# }

# resource "aws_ecs_task_definition" "aws_ecs_task" {
#   family             = "platform-training-ecs-task"
#   network_mode       = "awsvpc"
#   task_role_arn      = aws_iam_role.ecs_exec.arn
#   execution_role_arn = "arn:aws:iam::586634938182:role/ecsTaskExecutionRole"

#   container_definitions = jsonencode([
#     {
#       "name" : var.platform_container_name,
#       "image" : var.platform_image,
#       "portMappings" : [
#         {
#           "containerPort" : 80,
#           "hostPort" : var.platform_container_port,
#           "protocol" : "tcp",
#           "appProtocol" : "http",
#         }
#       ],
#       "essential" : true,
#       "logConfiguration" : {
#         "logDriver" : "awslogs",
#         "options" : {
#           "awslogs-group" : aws_cloudwatch_log_group.platform_logs.name,
#           "awslogs-region" : "eu-west-2",
#           "awslogs-stream-prefix" : "platform-kerginx"
#         }
#       },
#     }
#   ])
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = 256
#   memory                   = 512
#   runtime_platform {
#     cpu_architecture        = "X86_64"
#     operating_system_family = "LINUX"
#   }
# }

# data "aws_vpc" "default_vpc" {
#   default = true
# }

# data "aws_subnets" "default_subnet" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.default_vpc.id]
#   }
# }

# data "aws_security_groups" "vpc_security_groups" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.default_vpc.id]
#   }
# }

# resource "aws_lb" "ecs_lb" {
#   name               = "platform-training-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = data.aws_security_groups.vpc_security_groups.ids
#   subnets            = data.aws_subnets.default_subnet.ids
# }

# resource "aws_lb_target_group" "ecs_lb_target" {
#   name     = "platform-training-ecs-target"
#   port     = 80
#   protocol = "HTTP"
#   # port        = 443
#   # protocol    = "HTTPS"
#   target_type = "ip"
#   vpc_id      = data.aws_vpc.default_vpc.id
#   health_check {
#     protocol = "HTTP"
#   }
# }

# resource "aws_lb_listener" "ecs_lb_listener" {
#   load_balancer_arn = aws_lb.ecs_lb.arn
#   port              = 80
#   protocol          = "HTTP"
#   # port              = 443
#   # protocol          = "HTTPS"  

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.ecs_lb_target.arn
#   }
# }

# resource "aws_ecs_service" "ecs_service" {
#   name            = "platform-training-ecs-service"
#   launch_type     = "FARGATE"
#   cluster         = aws_ecs_cluster.aws_ecs.id
#   task_definition = aws_ecs_task_definition.aws_ecs_task.arn
#   desired_count   = 1
#   # allow commands to be executed via aws cli
#   enable_execute_command = true

#   network_configuration {
#     security_groups  = data.aws_security_groups.vpc_security_groups.ids
#     subnets          = data.aws_subnets.default_subnet.ids
#     assign_public_ip = true
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.ecs_lb_target.arn
#     container_name   = var.platform_container_name
#     container_port   = var.platform_container_port
#   }

#   lifecycle {
#     ignore_changes = [desired_count]
#   }
# }

# resource "aws_appautoscaling_target" "ecs_target" {
#   min_capacity       = 1
#   max_capacity       = 4
#   resource_id        = "service/${aws_ecs_cluster.aws_ecs.name}/${aws_ecs_service.ecs_service.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"
# }

# resource "aws_appautoscaling_policy" "ecs_scaling" {
#   name               = "platform-training-ecs-autoscale-policy"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.ecs_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }

#     target_value       = 70
#     scale_in_cooldown  = 300
#     scale_out_cooldown = 300
#   }
# }

# resource "aws_cloudwatch_log_group" "platform_logs" {
#   name = "/ecs/platform-training-logs"

#   retention_in_days = 1
# }

# data "aws_cloudfront_cache_policy" "disabled" {
#   name = "Managed-CachingDisabled"
# }

# resource "aws_cloudfront_distribution" "ecs_distribution" {
#   origin {
#     domain_name = aws_lb.ecs_lb.dns_name
#     origin_id   = aws_lb.ecs_lb.id

#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "http-only"
#       # origin_protocol_policy = "https-only"
#       origin_ssl_protocols = ["TLSv1"]
#     }
#   }

#   enabled    = true
#   web_acl_id = aws_wafv2_web_acl.waf.arn

#   default_cache_behavior {
#     cache_policy_id        = data.aws_cloudfront_cache_policy.disabled.id
#     allowed_methods        = ["GET", "HEAD"]
#     cached_methods         = ["GET", "HEAD"]
#     target_origin_id       = aws_lb.ecs_lb.id
#     viewer_protocol_policy = "redirect-to-https"
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "whitelist"
#       locations        = ["GB"]
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }
# }

# resource "aws_wafv2_web_acl" "waf" {
#   provider = aws.us_east

#   name  = "platform-cdn-waf"
#   scope = "CLOUDFRONT"

#   default_action {
#     allow {
#     }
#   }

#   rule {
#     name     = "CommonRuleSet"
#     priority = 1

#     override_action {
#       count {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       metric_name                = "waf-common-rule-set"
#       cloudwatch_metrics_enabled = false
#       sampled_requests_enabled   = false
#     }
#   }


#   rule {
#     name     = "RateLimit"
#     priority = 2

#     action {
#       block {}
#     }

#     statement {
#       rate_based_statement {
#         limit              = 300
#         aggregate_key_type = "IP"
#       }
#     }

#     visibility_config {
#       metric_name                = "waf-rate-limit"
#       cloudwatch_metrics_enabled = false
#       sampled_requests_enabled   = false
#     }
#   }

#   visibility_config {
#     metric_name                = "waf-metric"
#     cloudwatch_metrics_enabled = false
#     sampled_requests_enabled   = false
#   }
# }
