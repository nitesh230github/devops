provider "aws" {
  region = "us-east-1"
}


resource "aws_s3_bucket" "cicd_bucket" {
  bucket = "cicd_bucket230"
}
