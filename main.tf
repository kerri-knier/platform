

provider "aws" {
  region = "eu-west-2"
}

variable "image" {}

resource "aws_ecr_repository" "aws_ecr" {
  name                 = "platform-training-kerginx"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_s3_bucket" "test-bucket" {
  bucket = "s3-test-bucket"
}

resource "aws_ecs_cluster" "aws_ecs" {
  name = "platform-training-cluster"
}
# resource "aws_ecs_cluster" "aws_ecs_TEST" {
#   name = "platform-training-cluster-TEST"
# }

# resource "aws_ecs_task_definition" "aws_ecs_task" {
#   family = "platform-training-ecs-task"
#   network_mode = "awsvpc"
#   container_definitions = jsonencode([
#     {
#       "name": "platform-training-app",
#       "image": var.image
#       "portMappings": [
#         {
#           "containerPort": 80,
#           "hostPort": 80,
#           "protocol": "tcp",
#         }
#       ],
#       "essential": true, 
#             "entryPoint": [
#                 "sh",
# 	              "-c"
#             ], 
#             "command": [
#                 "/bin/sh -c \"echo '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
#             ]
#     }
#   ])
# }