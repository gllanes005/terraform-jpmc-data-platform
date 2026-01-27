terraform {
  backend "s3" {
    bucket         = "gabriel-jpmc-terraform-state"
    key            = "prod/data-platform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "gabriel-jpmc-terraform-locks"
    encrypt        = true
  }
}