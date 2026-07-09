variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "codap-prod"
}

variable "cluster_version" {
  type    = string
  default = "1.35"
}

variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "admin_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "admin_principal_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "CODAP"
    Environment = "prod"
    Owner       = "DevOps"
    ManagedBy   = "Terraform"
  }
}
