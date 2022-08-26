# resource "aws_kms_key" "backups" {
#   provider = aws.dr

#   description = "KMS key for AWS backups"
#   deletion_window_in_days = 10
# }

# resource "aws_backup_vault" "dr_region" {
#   provider = aws.dr

#   name = "dr-region"
#   kms_key_arn = aws_kms_key.backups.arn
# }

# output "aws_backup_vault" {
#   value = aws_backup_vault.dr_region
# }
