# data "aws_caller_identity" "main" {}

# data "aws_region" "dr" {}

# # Only one service role per account required
# # resource "aws_iam_service_linked_role" "elasticsearch" {}

# resource "aws_security_group" "elasticsearch" {
#   count = local.dr_enabled ? 1 : 0

#   name_prefix = "elasticsearch"
#   vpc_id = local.vpc_id

#   ingress {
#     cidr_blocks = ["172.31.0.0/16"]
#     from_port = 443
#     to_port = 443
#     protocol = "tcp"
#   }
# }

# resource "aws_iam_role" "elasticsearch" {
#   count = local.dr_enabled ? 1 : 0

#   name_prefix = "elasticsearch"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "es.amazonaws.com"
#         }
#       },
#     ]
#   })
# }

# resource "aws_iam_role_policy" "elasticsearch" {
#   count = local.dr_enabled ? 1 : 0

#   name_prefix = "elasticsearch"
#   role = aws_iam_role.elasticsearch.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "es:*",
#         ]
#         Effect = "Allow"
#         Resource = "arn:aws:es:${data.aws_region.dr.name}:${data.aws_caller_identity.main.account_id}:domain/${local.elasticsearch_name}/*"
#       },
#     ]
#   })
# }

# resource "aws_elasticsearch_domain" "test" {
#   count = local.dr_event ? 1 : 0

#   domain_name = local.elasticsearch_name
#   elasticsearch_version = "OpenSearch_1.1"

#   cluster_config {
#     instance_count = 3
#     instance_type = "t3.small.elasticsearch"
#     zone_awareness_enabled = true

#     zone_awareness_config {
#       availability_zone_count = 3
#     }
#   }

#   vpc_options {
#     subnet_ids = local.subnets
#     security_group_ids = [aws_security_group.elasticsearch.id]
#   }

#   access_policies = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Principal": {
#           "AWS": "*"
#         },
#         "Action": "es:*",
#         "Resource": "arn:aws:es:${data.aws_region.dr.name}:${data.aws_caller_identity.main.account_id}:domain/${local.name_elasticsearch}/*"
#       }
#     ]
#   })

#   snapshot_options {
#     automated_snapshot_start_hour = 23
#   }

#   ebs_options {
#     ebs_enabled = true
#     volume_size = 15
#   }

#   depends_on = [aws_iam_service_linked_role.elasticsearch]
# }
