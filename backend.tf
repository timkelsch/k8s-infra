terraform {
  backend "s3" {
    bucket = "terraform-state-975049962234"
    # key    = "your-project/terraform.tfstate"
    dynamodb_table = "terraform-state-975049962234"
    region = "us-west-2" # Oregon
  }
}