terraform {
  backend "s3" {
    bucket = "terrafrom-backend-us-east-2"
    key    = "project/terraform.tfstate"
    region = "us-east-2"
    encrypt = true
  }
}
