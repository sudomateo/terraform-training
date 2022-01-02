terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {}

resource "aws_s3_bucket" "terraform_training" {
  bucket_prefix = "terraform-training"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_training" {
  bucket = aws_s3_bucket.terraform_training.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_training" {
  name           = "terraform-training"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "terraform_training_bucket" {
  value = aws_s3_bucket.terraform_training.bucket
}

output "terraform_training_dynamodb_table" {
  value = aws_dynamodb_table.terraform_training.id
}
