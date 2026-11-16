output "aws_region" {
  value = local.region
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.hello_service.repository_url
}

# Assumable from any branch build; ECR push only.
output "github_push_role_arn" {
  value = aws_iam_role.github_push.arn
}

# Assumable only from jobs in the staging/production GitHub Environments.
output "github_deploy_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name} --profile sandbox"
}
