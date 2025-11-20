terraform {
  backend "s3" {
    bucket = "terrafrom-backend-aj"
    key    = "project/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}
