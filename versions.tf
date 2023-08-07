terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.55"
    }
  }

  backend "s3" {
    bucket = "kerri-terraform-state"
    key    = "platform-training/terraform.tfstate"
    region = "eu-west-2"
  }
}