terraform {
  backend "s3" {
    bucket = "kulud-backend-terraform"
    key    = "project/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}
