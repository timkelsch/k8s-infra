# Bootstrap resources module
module "bootstrap-kops" {
  source = "./modules/kops-bootstrap"
  count  = var.deploy_kops-bootstrap ? 1 : 0 # Run only if deploy_bootstrap is true
}

output "kops_cluster_state_s3-bucket_name" {
  value = module.bootstrap-kops[0].kops_cluster_state_s3-bucket_name
}
output "account_id" {
  value = module.bootstrap-kops[0].account_id
}

output "caller_arn" {
  value = module.bootstrap-kops[0].caller_arn
}

output "aws_region" {
  value = module.bootstrap-kops[0].aws_region
}