provider "aws" {
  region  = "us-east-1"
}

module "my_stack" {
  source = "./modules/my-stack"
}

# Capture all the outputs from the module instantiation above
output "my_stack_outputs" {
  value = module.my_stack
}
