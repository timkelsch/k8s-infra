terraform {
  backend "s3" {
    bucket         = "tf-state-the-kubeground"
    key            = "thekubeground"
    dynamodb_table = "tf-state-the-kubeground"
    region         = "us-west-2" # Oregon
  }
}
