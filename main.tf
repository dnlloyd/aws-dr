provider "aws" {
  region  = "us-east-1"
}

# module "my_stack" {
#   source = "./modules/my-stack"
# }

# Capture all the outputs from the module instantiation above
# output "my_stack_outputs" {
#   value = module.my_stack
# }

resource "aws_s3_bucket" "es_snap" {
  bucket_prefix = "es_snap"
}

resource "aws_s3_bucket_acl" "es_snap_bucket_acl" {
  bucket = aws_s3_bucket.es_snap.id
  acl = "private"
}

resource "aws_s3_bucket_versioning" "es_snap" {
  bucket = aws_s3_bucket.es_snap.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "es_snap_bucket" {
  value = aws_s3_bucket.es_snap
}
