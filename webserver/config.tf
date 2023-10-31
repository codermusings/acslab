terraform {
  backend "s3" {
    bucket = "sanahbucket"
    key    = "dev/webserver/terraform.tfstate"
    region = "us-east-1"
  }
}
