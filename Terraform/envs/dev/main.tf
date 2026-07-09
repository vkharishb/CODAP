module "vpc" {
  source = "../../modules/vpc"

  name                  = "codap-dev"
  cluster_name          = var.cluster_name
  azs                   = var.azs
  cidr_block            = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
  single_nat_gateway    = true # cost-saver for a demo cluster; use one-per-AZ in prod

  tags = {
     Environment = "dev" 
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name            = var.cluster_name
  cluster_version         = var.cluster_version
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  public_subnet_ids       = module.vpc.public_subnet_ids
  admin_principal_arn     = var.admin_principal_arn
  node_instance_types     = ["t3.medium"]
  node_desired_size       = 2
  node_min_size           = 1
  node_max_size           = 4
  endpoint_public_access  = true
  public_access_cidrs     = var.admin_cidr_blocks

  tags = { Environment = "dev" }
}

module "dora_service_irsa" {
  source = "../../modules/irsa"

  role_name             = "codap-dev-dora-service"
  oidc_provider_arn     = module.eks.oidc_provider_arn
  oidc_provider_url     = module.eks.oidc_provider_url
  namespace             = "dora-metrics"
  service_account_name  = "dora-metrics-service"
  policy_arns           = [] # attach a scoped Secrets Manager read policy here

  tags = { Environment = "dev" }
}
