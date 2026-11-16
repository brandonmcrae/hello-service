# Public subnets only, no NAT gateway: nodes get public IPs and reach the
# internet directly. Cheap and fast; not production-grade.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = local.name
  cidr = "10.0.0.0/16"

  azs            = ["${local.region}a", "${local.region}b"]
  public_subnets = ["10.0.0.0/20", "10.0.16.0/20"]

  map_public_ip_on_launch = true
  enable_nat_gateway      = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
}
