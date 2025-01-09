terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.81.0" 
    }
  }
    backend "s3" {
    bucket = "pka.in.net-dev"
    key    = "user-deploy"
    region = "us-east-1"
    dynamodb_table = "pka.in.net-dev"
  }
}

provider "aws" {
  region = "us-east-1"
}
