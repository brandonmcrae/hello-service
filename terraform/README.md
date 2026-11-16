# terraform

A throwaway EKS test cluster for hello-service, in the sandbox AWS account (`241088755532`, `ca-central-1`). Run it by hand: apply at the start of a session, destroy at the end. CI never runs this; it only uses the outputs.

## What it creates

- A VPC with two public subnets and no NAT gateway
- An EKS 1.37 cluster with one `t3.small` node
- An ECR repo `hello-service` with immutable tags
- A GitHub OIDC provider and two roles for GitHub Actions in `brandonmcrae/hello-service`:
  - `hello-eks-test-github-push`: any branch build can assume it; ECR push only
  - `hello-eks-test-github-actions`: only jobs in the `staging` or `production` GitHub Environment can assume it; EKS cluster-admin

## Run it

The AWS provider can't use the `sandbox` profile directly: the profile chains from an `aws login` session, which the provider doesn't support. Export short-lived credentials first. They last about an hour.

```sh
eval "$(aws configure export-credentials --profile sandbox --format env)"
unset AWS_PROFILE

terraform init
terraform apply     # ~15 minutes
$(terraform output -raw kubeconfig_command)

terraform destroy   # end of session; also deletes all images in ECR
```

The provider refuses to run against any account other than sandbox.

## Outputs for CI

`aws_region`, `ecr_repository_url`, `github_push_role_arn`, `github_deploy_role_arn` and `cluster_name` come out the same every session, so CI only needs to be configured once. They're stored as GitHub repository variables (`AWS_REGION`, `ECR_REPOSITORY_URL`, `AWS_PUSH_ROLE_ARN`, `AWS_DEPLOY_ROLE_ARN`, `EKS_CLUSTER_NAME`).
