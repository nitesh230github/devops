terraform {
  backend "s3" {
    bucket         = "terraformlock-2026-devops"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
