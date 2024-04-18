// Cloning Terraform src code to /var/folders/99/ybl8q31d3w598svh5jclmbrc0000gn/T/terraform_src...
 code has been checked out.

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

variable kops_user_name {
  description = "Name of the IAM user that kops uses"
  type = string
  default = "KopsUser"
}

resource "aws_iam_group" "kops_group" {
  // CF Property(ManagedPolicyArns) = [
  //   "AmazonEC2FullAccess",
  //   "AmazonRoute53FullAccess",
  //   "AmazonS3FullAccess",
  //   "IAMFullAccess",
  //   "AmazonVPCFullAccess",
  //   "AmazonSQSFullAccess",
  //   "AmazonEventBridgeFullAccess"
  // ]
}

resource "aws_iam_user" "kops_user" {
  name = var.kops_user_name
}

resource "aws_s3_bucket" "oidc_bucket" {
  acl = "public-read"
}

resource "aws_s3_bucket_policy" "oidc_bucket_policy" {
  policy = jsonencode({
      Id = "MyPolicy"
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "PublicReadForGetBucketObjects"
          Effect = "Allow"
          Principal = "*"
          Action = "s3:GetObject"
          Resource =           // Unable to resolve Fn::GetAtt with value: [
          //   "OidcBucket"
          // ]
        },
        {
          Sid = "AdminPerms"
          Effect = "Allow"
          Principal = {
            AWS = [
              aws_iam_user.kops_user.arn,
              "arn:aws:iam::287140326780:user/sam-user"
            ]
          }
          Action = "s3:*"
          Resource =           // Unable to resolve Fn::GetAtt with value: [
          //   "OidcBucket"
          // ]
        }
      ]
    }
  )
  bucket = aws_s3_bucket.oidc_bucket.id
}

resource "aws_s3_bucket" "kops_cluster_state_bucket" {
  versioning {
    // CF Property(Status) = "Enabled"
  }
  bucket = {
    ServerSideEncryptionConfiguration = [
      {
        ServerSideEncryptionByDefault = {
          SSEAlgorithm = "aws:kms"
          KMSMasterKeyID = aws_kms_key.bucket_key.arn
        }
      }
    ]
  }
  // CF Property(PublicAccessBlockConfiguration) = {
  //   BlockPublicAcls = true
  //   BlockPublicPolicy = true
  // }
}

resource "aws_s3_bucket_policy" "kops_cluster_state_bucket_policy" {
  policy = jsonencode({
      Id = "MyPolicy"
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "AdminPerms"
          Effect = "Allow"
          Principal = "arn:aws:iam::287140326780:user/sam-user"
          Action = "s3:*"
          Resource = aws_s3_bucket.kops_cluster_state_bucket.arn
        }
      ]
    }
  )
  bucket = aws_s3_bucket.kops_cluster_state_bucket.id
}

resource "aws_kms_key" "bucket_key" {
  is_enabled = true
  enable_key_rotation = true
  multi_region = true
  policy = {
    Version = "2012-10-17"
    Id = "bucket-policy-1"
    Statement = [
      {
        Sid = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  }
}
