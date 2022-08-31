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

resource "aws_kms_key" "backups" {
  description = "KMS key for AWS backups"
  deletion_window_in_days = 10
}

resource "aws_backup_vault" "backups" {
  name = "primary-region"
  kms_key_arn = aws_kms_key.backups.arn
}

resource "aws_backup_plan" "main" {
  name = "RdsBackupPlan"

  rule {
    rule_name = "main_backup"
    target_vault_name = aws_backup_vault.backups.name
    schedule = "cron(30 21 * * ? *)"
    enable_continuous_backup = true

    lifecycle {
      delete_after = 14
    }

    dynamic "copy_action" {
      for_each = var.dr_enabled ? ["do-nothing"] : []

      content {
        destination_vault_arn = var.dr_remote_state.outputs.rds_with_backups_outputs.aws_backup_vault.backups.arn
      }
    }

    
  }
}

resource "aws_iam_role" "aws_backup" {
  name_prefix = "AwsBackup"
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

output "aws_backup_vault" {
  value = aws_backup_vault.backups
}
