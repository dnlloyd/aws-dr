provider "aws" {
  region  = "us-east-1"
}

module "my_stack" {
  source = "./modules/my-stack"
}

# Net new: Capture all the outputs from the module instantiation above
output "rep_test_outputs" {
  value = module.my_stack
}

resource "aws_db_instance" "default" {
  db_name = "test"
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

# resource "aws_kms_key" "backups" {
#   description = "KMS key for AWS backups"
#   deletion_window_in_days = 10
# }

# resource "aws_backup_vault" "main" {
#   name = "main"
#   kms_key_arn = aws_kms_key.backups.arn
# }
