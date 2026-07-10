variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "codap-dev"
}

variable "cluster_version" {
  description = "EKS Kubernetes minor version. Use an AWS EKS supported version."
  type        = string
  default     = "1.35"
}

variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to reach the EKS public API endpoint. Use your /32 IP, not 0.0.0.0/0, outside demo use."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_principal_arn" {
  description = "IAM user or role ARN that should get EKS admin access."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    Project     = "CODAP"
    Environment = "dev"
    Owner       = "DevOps"
    ManagedBy   = "Terraform"
  }
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "717090908227"
}