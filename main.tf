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
