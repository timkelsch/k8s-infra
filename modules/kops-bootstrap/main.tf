module "kops_group" {
  source                            = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version                           = "5.39.0"
  name                              = "KopsGroup"
  attach_iam_self_management_policy = false
  group_users                       = [aws_iam_user.kops_user.name]
  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
  ]
}

# module "kops_user" {
#   source                        = "terraform-aws-modules/iam/aws//modules/iam-user"
#   version                       = "5.39.0"
#   name                          = "kops"
#   create_iam_user_login_profile = false
#   create_iam_access_key         = false
# }

resource "aws_iam_user" "kops_user" {
  name = "kops"
}

module "oidc_s3-bucket" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  version                  = "4.1.2"
  bucket                   = "oidc-${random_id.random_string.hex}"
  acl                      = "public-read"
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  block_public_acls        = false
  block_public_policy      = false
  ignore_public_acls       = false
  restrict_public_buckets  = false
}

resource "aws_s3_bucket_policy" "oidc_bucket_policy" {
  bucket = module.oidc_s3-bucket.s3_bucket_id
  policy = jsonencode({
    Id      = "MyPolicy"
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadForGetBucket"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Resource = [
          "${module.oidc_s3-bucket.s3_bucket_arn}/*",
          "${module.oidc_s3-bucket.s3_bucket_arn}"
        ]
      },
      {
        Sid    = "AdminPerms"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_user.kops_user.arn,
            "arn:aws:iam::${local.account_id}:user/admin"
          ]
        }
        Action = "s3:*"
        Resource = [
          "${module.oidc_s3-bucket.s3_bucket_arn}",
          "${module.oidc_s3-bucket.s3_bucket_arn}/*"
        ]
      }
    ]
    }
  )
}

module "kops_cluster_state_s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"
  bucket  = "kops-cluster-state-${random_id.random_string.hex}"
  server_side_encryption_configuration = {
    rule = {
      ApplyServerSideEncryptionByDefault = {
        SSEAlgorithm = "AES256"
      }
    }
  }
  versioning = {
    enabled = true
  }
}

resource "aws_s3_bucket_policy" "kops_cluster_state_bucket_policy" {
  bucket = module.kops_cluster_state_s3-bucket.s3_bucket_id
  policy = jsonencode({
    Id      = "MyPolicy"
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AdminPerms"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_user.kops_user.arn,
            "arn:aws:iam::${local.account_id}:user/admin"
          ]
        }
        Action = "s3:*"
        Resource = [
          "${module.kops_cluster_state_s3-bucket.s3_bucket_arn}",
          "${module.kops_cluster_state_s3-bucket.s3_bucket_arn}/*"
        ]
      }
    ]
    }
  )
}

module "kops_cluster_backup_s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"
  bucket  = "kops-cluster-backup-${random_id.random_string.hex}"
  server_side_encryption_configuration = {
    rule = {
      ApplyServerSideEncryptionByDefault = {
        SSEAlgorithm = "AES256"
      }
    }
  }
  versioning = {
    enabled = true
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = module.kops_cluster_backup_s3-bucket.s3_bucket_id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_policy" "kops_cluster_backup_bucket_policy" {
  bucket = module.kops_cluster_backup_s3-bucket.s3_bucket_id
  policy = jsonencode({
    Id      = "MyPolicy"
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AdminPerms"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_user.kops_user.arn,
            "arn:aws:iam::${local.account_id}:user/admin"
          ]
        }
        Action = "s3:*"
        Resource = [
          "${module.kops_cluster_backup_s3-bucket.s3_bucket_arn}",
          "${module.kops_cluster_backup_s3-bucket.s3_bucket_arn}/*"
        ]
      }
    ]
    }
  )
}

resource "random_id" "random_string" {
  byte_length = 8

}

output "kops_cluster_state_s3-bucket_name" {
  value = module.kops_cluster_state_s3-bucket.s3_bucket_id
}

data "aws_caller_identity" "current" {}

locals {
    account_id = data.aws_caller_identity.current.account_id
}
