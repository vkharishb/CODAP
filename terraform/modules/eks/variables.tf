variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.35"

  validation {
    condition     = can(regex("^1\\.(3[0-9])$", var.cluster_version))
    error_message = "cluster_version must look like \"1.35\" and must be an AWS EKS supported minor version."
  }
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.public_access_cidrs : can(cidrhost(c, 0))])
    error_message = "Each entry in public_access_cidrs must be a valid CIDR block."
  }
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 4

  validation {
    condition     = var.node_max_size >= var.node_desired_size && var.node_desired_size >= var.node_min_size
    error_message = "Node group sizing must satisfy node_min_size <= node_desired_size <= node_max_size."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "admin_principal_arn" {
  description = "IAM role/user ARN to grant EKS cluster-admin access."
  type        = string
  default     = ""
}

variable "install_alb_controller" {
  description = "Whether to install the AWS Load Balancer Controller Helm chart from this module"
  type        = bool
  default     = false
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
