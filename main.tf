

provider "aws" {
  region = "eu-west-2"
}

resource "aws_ecr_repository" "aws_ecr" {
  name                 = "platform-training"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}