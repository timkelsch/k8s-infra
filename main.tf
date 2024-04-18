# Configure remote backend (replace with your backend details)
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "your-project/terraform.tfstate"
  }
}

# Optional global variables file
variable "deploy_kops-bootstrap" {
  # Set to true to deploy bootstrap resources
  default = false
}

variable "deploy_main" {
  # Set to true to deploy bootstrap resources
  default = false
}

# Bootstrap resources module
module "bootstrap-kops" {
  source  = "./modules/kops-bootstrap"
  count   = var.deploy_kops-bootstrap ? 1 : 0  # Run only if deploy_bootstrap is true
}

# Standard resources module
module "main" {
  source = "./modules/main"
  count   = var.deploy_main ? 1 : 0  # Run only if deploy_bootstrap is true
}
