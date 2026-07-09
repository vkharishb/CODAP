module "vpc" {
  source = "../../modules/vpc"

  name                 = "codap-prod"
  cluster_name         = var.cluster_name
  azs                  = var.azs
  cidr_block           = "10.20.0.0/16"
  public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
  single_nat_gateway   = false

  tags = var.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name           = var.cluster_name
  cluster_version        = var.cluster_version
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  public_subnet_ids      = module.vpc.public_subnet_ids
  admin_principal_arn    = var.admin_principal_arn
  node_instance_types    = ["t3.large"]
  node_desired_size      = 3
  node_min_size          = 2
  node_max_size          = 6
  endpoint_public_access = false
  public_access_cidrs    = var.admin_cidr_blocks

  tags = var.tags
}
