variable "name" {
  description = "Name prefix for all VPC resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name, used to tag subnets for the AWS load balancer / autoscaler controllers"
  type        = string
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for all private subnets instead of one per AZ (cheaper, less resilient - good for a demo/portfolio cluster)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags applied to all resources"
  type        = map(string)
  default     = {}
}
