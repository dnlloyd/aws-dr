provider "aws" {
  region  = "us-east-1"
}

data "terraform_remote_state" "dr" {
  backend = "remote"

  config = {
    organization = "fhc-dan"
    workspaces = {
      name = "htest-dr"
    }
  }
}

#################################################################
# Module Web: CloudFront and ALB

module "web" {
  source = "./modules/web"

  domain = "fhcdan.net"
  site_dns = "fhcdan.net"

  # dr_remote_state = data.terraform_remote_state.dr.outputs
  # dr_enabled = false
  # dr_cutover = false
}

#################################################################
# Module RDS with AWS Backup

# module "rds_with_backups" {
#   source = "./modules/rds-with-backup"

#   dr_remote_state = data.terraform_remote_state.dr.outputs
#   dr_enabled = false
# }

#################################################################
# Module stack

# module "my_stack" {
#   source = "./modules/my-stack"
# }

# Capture all the outputs from the module instantiation above
# output "my_stack_outputs" {
#   value = module.my_stack
# }

#################################################################
# S3 bucket replication

# resource "aws_s3_bucket" "es_snap" {
#   bucket_prefix = "essnap"
# }

# resource "aws_s3_bucket_acl" "es_snap_bucket_acl" {
#   bucket = aws_s3_bucket.es_snap.id
#   acl = "private"
# }

# resource "aws_s3_bucket_versioning" "es_snap" {
#   bucket = aws_s3_bucket.es_snap.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# output "es_snap_bucket" {
#   value = aws_s3_bucket.es_snap
# }
