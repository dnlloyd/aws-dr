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
  # backup_retention_period = 14
  # backup_window = "15:10-16:10"
  apply_immediately = true
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

resource "aws_kms_key" "backups_primary" {
  description = "KMS key for AWS backups"
  deletion_window_in_days = 10
}

resource "aws_backup_vault" "primary_region" {
  name = "primary-region"
  kms_key_arn = aws_kms_key.backups_primary.arn
}

resource "aws_backup_plan" "main" {
  name = "MainBackupPlan"

  rule {
    rule_name = "main_backup"
    target_vault_name = aws_backup_vault.primary_region.name
    schedule = "cron(52 16 * * ? *)"
    enable_continuous_backup = true

    lifecycle {
      delete_after = 14
    }

    copy_action {
      destination_vault_arn = data.terraform_remote_state.dr.outputs.aws_backup_vault.arn
    }
  }
}

resource "aws_iam_role" "aws_backup" {
  name = "AwsBackup"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": ["sts:AssumeRole"],
        "Effect": "allow",
        "Principal": {
          "Service": ["backup.amazonaws.com"]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role = aws_iam_role.aws_backup.name
}

resource "aws_backup_selection" "rds" {
  iam_role_arn = aws_iam_role.aws_backup.arn
  name = "rds_backup_selection"
  plan_id = aws_backup_plan.main.id

  resources = [aws_db_instance.default.arn]
}