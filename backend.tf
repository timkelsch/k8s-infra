terraform {
  backend "s3" {
    bucket = "tf-state-287140326780"
    key    = "playground/dev"
    dynamodb_table = "tf-state-287140326780"
    region = "us-west-2" # Oregon
  }
}