# Lets GitHub Actions in this repo assume AWS roles without long-lived keys.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# Two roles, split by what the workflow job is doing. The OIDC `sub` claim says
# where the token came from:
#   - a job without `environment:` -> repo:<owner>/<repo>:ref:refs/heads/<branch>
#   - a job with `environment: X`  -> repo:<owner>/<repo>:environment:X
#
# push:   any branch build can push images to ECR, and nothing else.
# deploy: only jobs running in the staging or production GitHub Environment can
#         reach the cluster. Approval rules and branch restrictions on those
#         environments are the gate for deploys.
locals {
  github_role_subjects = {
    push = ["repo:${local.github_repo}:ref:refs/heads/*"]
    deploy = [
      "repo:${local.github_repo}:environment:staging",
      "repo:${local.github_repo}:environment:production",
    ]
  }
}

data "aws_iam_policy_document" "github_trust" {
  for_each = local.github_role_subjects

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value
    }
  }
}

# --- push role: ECR push only -------------------------------------------------

resource "aws_iam_role" "github_push" {
  name               = "${local.name}-github-push"
  assume_role_policy = data.aws_iam_policy_document.github_trust["push"].json
}

data "aws_iam_policy_document" "github_push" {
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [aws_ecr_repository.hello_service.arn]
  }
}

resource "aws_iam_role_policy" "github_push" {
  name   = "ecr-push"
  role   = aws_iam_role.github_push.id
  policy = data.aws_iam_policy_document.github_push.json
}

# --- deploy role: cluster access, ECR read-only -------------------------------
# Keeps the original role name so its ARN, and the EKS access entry in eks.tf
# that grants it cluster-admin, stay the same.

resource "aws_iam_role" "github_actions" {
  name               = "${local.name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_trust["deploy"].json
}

data "aws_iam_policy_document" "github_deploy" {
  statement {
    sid       = "EcrReadImages"
    actions   = ["ecr:DescribeImages"]
    resources = [aws_ecr_repository.hello_service.arn]
  }

  statement {
    sid       = "EksKubeconfig"
    actions   = ["eks:DescribeCluster"]
    resources = [module.eks.cluster_arn]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "eks-deploy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_deploy.json
}
