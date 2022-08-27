provider "aws" {
  alias = "dr"
  region  = "us-east-2"
}

provider "aws" {
  alias = "primary"
  region  = "us-east-1"
}

locals {
  elasticsearch_name = "test"
  vpc_id = "vpc-065b33a8baa73e2a3"
  subnets = ["subnet-0799f4a5fa38ae5f7", "subnet-07f0c07531ff40032", "subnet-00e8e661d1aa7a9db"]

  dr_enabled = true
  dr_event = true
}

data "terraform_remote_state" "primary" {
  backend = "remote"

  config = {
    organization = "fhc-dan"
    workspaces = {
      name = "htest"
    }
  }
}

# module "my_stack" {
#   source = "../modules/my-stack"

#   providers = {
#     aws = aws.dr
#     aws.shared = aws.primary
#   }

#   dr_enabled = local.dr_enabled
#   dr_event = local.dr_event
#   primary_remote_state = data.terraform_remote_state.primary.outputs
# }

####################################################################

resource "aws_s3_bucket" "es_snap_dr" {
  provider = aws.dr

  bucket_prefix = "essnapdr"
}

resource "aws_s3_bucket_acl" "es_snap_dr_bucket_acl" {
  provider = aws.dr

  bucket = aws_s3_bucket.es_snap_dr.id
  acl = "private"
}

resource "aws_s3_bucket_versioning" "es_snap_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.es_snap_dr.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "s3_replication_es" {
  provider = aws.dr

  name = "S3ReplicationTestEs"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "s3.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

resource "aws_iam_policy" "s3_replication_es" {
  provider = aws.dr

  name = "S3ReplicationTestEs"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        "Effect": "Allow",
        "Resource": [
          "${data.terraform_remote_state.primary.outputs.es_snap_bucket.arn}",
          "${aws_s3_bucket.es_snap_dr.arn}"
        ]
      },
      {
        "Action": [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ],
        "Effect": "Allow",
        "Resource": [
          "${data.terraform_remote_state.primary.outputs.es_snap_bucket.arn}/*",
          "${aws_s3_bucket.es_snap_dr.arn}/*"
        ]
      },
      {
        "Action": [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        "Effect": "Allow",
        "Resource": [
          "${aws_s3_bucket.es_snap_dr.arn}/*",
          "${data.terraform_remote_state.primary.outputs.es_snap_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Only create attachment in DR context
resource "aws_iam_role_policy_attachment" "replication_es" {
  provider = aws.dr

  role = aws_iam_role.s3_replication_es.name
  policy_arn = aws_iam_policy.s3_replication_es.arn
}

# In a DR context, the aws_s3_bucket_replication_configuration resource below uses the 
# primary region provider. We need to get the DR region bucket resource for the 
# destination
locals {
  es_snap_dr_bucket_arn = aws_s3_bucket.es_snap_dr.arn
}

# Replication from primary region to DR region
resource "aws_s3_bucket_replication_configuration" "replication_primary_to_dr" {
  provider = aws.primary

  role = aws_iam_role.s3_replication_es.arn
  bucket = data.terraform_remote_state.primary.outputs.es_snap_bucket.id

  rule {
    status = "Enabled"

    destination {
      bucket = local.es_snap_dr_bucket_arn
      storage_class = "STANDARD"
    }
  }
}

# Replication from DR region to primary region
resource "aws_s3_bucket_replication_configuration" "replication_dr_to_primary" {  
  provider = aws.dr

  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.es_snap_dr]

  role = aws_iam_role.s3_replication_es.arn
  bucket = aws_s3_bucket.es_snap_dr.id

  rule {
    status = "Enabled"

    destination {
      bucket = data.terraform_remote_state.primary.outputs.es_snap_bucket.arn
      storage_class = "STANDARD"
    }
  }
}
