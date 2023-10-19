terraform {
  backend "s3" {
    bucket = "kerri-terraform-state"
    key    = "platform-training/terraform.tfstate"
    region = "eu-west-2"
  }
}