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
      name = "s3-replication-testing"
    }
  }
}

module "my_stack" {
  source = "../modules/my-stack"

  providers = {
    aws = aws.dr
    aws.shared = aws.primary
  }

  dr_enabled = local.dr_enabled
  dr_event = local.dr_event
  primary_remote_state = data.terraform_remote_state.primary.outputs
}

