

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