terraform {
  backend "s3" {
    bucket         = "foundation-terraform-state-ltn"
    key            = "global/acm/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "foundation-terraform-locks"
    encrypt        = true
  }
}
