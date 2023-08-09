

provider "aws" {
  region = "eu-west-2"
  
  assume_role {
    role_arn = "arn:aws:iam::586634938182:role/platform-cicd-oidc"
  }
}

resource "aws_ecr_repository" "aws_ecr" {
  name                 = "platform-training"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}