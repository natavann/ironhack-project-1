terraform {
  required_providers {        
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }

  backend "s3" {
    bucket         = "voting-project-bucket-nata"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "voting-project-state-lock-nata"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

  