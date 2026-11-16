module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name
  kubernetes_version = "1.37"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # Public API endpoint, open to the internet; IAM auth is the only gate.
  endpoint_public_access       = true
  endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Whoever runs `terraform apply` gets cluster-admin.
  enable_cluster_creator_admin_permissions = true

  # Pod Identity (agent add-on below) replaces IRSA, so skip its OIDC provider.
  enable_irsa = false

  # No customer-managed KMS key (avoids a pending-deletion key per destroy)
  # and no control-plane logging.
  create_kms_key              = false
  encryption_config           = null
  enabled_log_types           = []
  create_cloudwatch_log_group = false

  addons = {
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    coredns    = {}
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"

      # Fixed size; scale by editing these and re-applying.
      min_size     = 1
      max_size     = 1
      desired_size = 1
    }
  }

  access_entries = {
    github_actions = {
      principal_arn = aws_iam_role.github_actions.arn

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}
