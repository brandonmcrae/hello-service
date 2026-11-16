locals {
  name   = "hello-eks-test"
  region = "ca-central-1"

  github_repo = "brandonmcrae/hello-service"
}

provider "aws" {
  region = local.region

  # Credentials come from the environment (see README). This hard-stops any
  # run that isn't pointed at the sandbox account.
  allowed_account_ids = ["241088755532"]

  default_tags {
    tags = {
      Project     = "hello-service"
      Environment = "test"
      ManagedBy   = "terraform"
    }
  }
}
