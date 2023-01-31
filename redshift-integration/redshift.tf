# # redshift serverless resources
# resource "aws_redshiftserverless_namespace" "namespace" {
#   namespace_name = "${local.name}-namespace"

#   admin_username       = local.redshift.admin_username
#   admin_user_password  = local.secrets.redshift_admin_password
#   db_name              = local.redshift.db_name
#   default_iam_role_arn = aws_iam_role.redshift_serverless_role.arn
#   iam_roles            = [aws_iam_role.redshift_serverless_role.arn]

#   tags = local.tags
# }

# resource "aws_redshiftserverless_workgroup" "workgroup" {
#   namespace_name = aws_redshiftserverless_namespace.namespace.id
#   workgroup_name = "${local.name}-workgroup"

#   base_capacity      = local.redshift.base_capacity
#   subnet_ids         = module.vpc.private_subnets
#   security_group_ids = [aws_security_group.redshift_serverless.id]

#   tags = local.tags
# }

# resource "aws_redshiftserverless_endpoint_access" "endpoint_access" {
#   endpoint_name = "${local.name}-endpoint"

#   workgroup_name = aws_redshiftserverless_workgroup.workgroup.id
#   subnet_ids     = module.vpc.private_subnets
# }

# # iam role
# resource "aws_iam_role" "redshift_serverless_role" {
#   name = "${local.name}-redshift-serverless-role"

#   assume_role_policy = data.aws_iam_policy_document.redshift_serverless_assume_role_policy.json
#   managed_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonS3FullAccess",
#     "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
#     "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess",
#     "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
#   ]
# }

# data "aws_iam_policy_document" "redshift_serverless_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type = "Service"
#       identifiers = [
#         "redshift.amazonaws.com",
#         "sagemaker.amazonaws.com",
#         "events.amazonaws.com",
#         "scheduler.redshift.amazonaws.com"
#       ]
#     }

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#     }
#   }
# }

resource "aws_security_group" "redshift_serverless" {
  name   = "${local.name}-redshift-serverless"
  vpc_id = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_security_group_rule" "redshift_vpn_inbound" {
  count                    = local.vpn.to_create ? 1 : 0
  type                     = "ingress"
  description              = "VPN access"
  security_group_id        = aws_security_group.redshift_serverless.id
  protocol                 = "tcp"
  from_port                = 5439
  to_port                  = 5439
  source_security_group_id = aws_security_group.vpn[0].id
}

resource "aws_security_group_rule" "redshift_msk_egress" {
  type              = "egress"
  description       = "lambda msk access"
  security_group_id = aws_security_group.redshift_serverless.id
  protocol          = "tcp"
  from_port         = 9098
  to_port           = 9098
  cidr_blocks       = ["0.0.0.0/0"]
}
