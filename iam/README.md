# IAM role guidance

Create separate CodeBuild service roles where practical:

- `codap-codebuild-ci-role`: logs, cache/artifacts, no infrastructure mutation.
- `codap-codebuild-terraform-plan-role`: S3 backend access and read/plan permissions.
- `codap-codebuild-terraform-apply-role`: Terraform apply permissions.
- `codap-codebuild-image-role`: configuration read plus ECR push.
- `codap-codebuild-deploy-role`: EKS discovery plus the EKS access entry/RBAC required by kubectl and Helm.
- `codap-codebuild-destroy-role`: tightly controlled Terraform destroy permissions.

The JSON files in this directory are starter policies. Terraform permissions depend on the AWS resources declared in the CODAP Terraform modules and therefore cannot be safely inferred from the workflow YAML alone.

## EKS access

IAM permission `eks:DescribeCluster` is not enough for `kubectl`. Add the deploy role as an EKS access entry and associate an appropriate access policy, or map it through your existing Kubernetes RBAC model.

Example administrator bootstrap command (scope it down after testing):

```powershell
aws eks create-access-entry `
  --cluster-name REPLACE_WITH_EKS_CLUSTER_NAME `
  --principal-arn arn:aws:iam::230477418786:role/codap-codebuild-deploy-role `
  --region ap-south-2 `
  --profile codap

aws eks associate-access-policy `
  --cluster-name REPLACE_WITH_EKS_CLUSTER_NAME `
  --principal-arn arn:aws:iam::230477418786:role/codap-codebuild-deploy-role `
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy `
  --access-scope type=cluster `
  --region ap-south-2 `
  --profile codap
```

Replace cluster-wide admin access with namespace-scoped or custom RBAC when the deployment requirements are confirmed.
