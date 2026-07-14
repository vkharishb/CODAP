resource "aws_iam_policy" "aws_load_balancer_controller" {
  name = "${var.cluster_name}-aws-load-balancer-controller"

  policy = file(
    "${path.module}/../../policies/aws-load-balancer-controller-v3.4.1.json"
  )

  tags = var.tags
}

module "aws_load_balancer_controller_irsa" {
  source = "../../modules/irsa"

  role_name            = "${var.cluster_name}-aws-load-balancer-controller"
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  namespace            = "kube-system"
  service_account_name = "aws-load-balancer-controller"

  policy_arns = [
    aws_iam_policy.aws_load_balancer_controller.arn
  ]

  tags = var.tags
}