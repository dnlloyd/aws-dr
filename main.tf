provider "aws" {
  region  = "us-east-1"
}

module "s3_rep_test" {
  source = "./modules/s3-replication-two-way"
}

# Net new: Capture all the outputs from the module instantiation above
output "rep_test_outputs" {
  value = module.s3_rep_test
}

locals {
  elasticsearch_name = "test"
  vpc_id = "vpc-065b33a8baa73e2a3"
  subnets = ["subnet-0799f4a5fa38ae5f7", "subnet-07f0c07531ff40032", "subnet-00e8e661d1aa7a9db"]
}

