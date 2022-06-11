terraform {
  required_version = ">= 0.13.1"
  backend "s3" {
    bucket = "test-us-west-2-terraform-state"
    key    = "test/terraform.tfstate"
    region = "us-west-2"

    dynamodb_table = "test-us-west-2-terraform-state"
    encrypt        = true
  }
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}