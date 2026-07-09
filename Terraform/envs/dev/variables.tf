variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "codap-dev"
}

variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to reach the EKS public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_version" {
  type    = string
  default = "1.35"  
}

variable "admin_principal_arn" {
  description = "IAM user or role ARN that should get EKS admin access."
  type        = string
  default     = ""
}