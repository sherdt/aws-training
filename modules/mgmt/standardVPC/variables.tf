variable "name" {
  description = "The name of the ressource."
  type        = string
}
variable "stage_name" {
  description = "The name of the stage (e.g. dev, test, stage, prod)"
  type        = string
}
variable "project_name" {
  description = "The name of the project (e.g. LinzMobile)"
  type        = string
}

variable "public_subnet_cidr" {
  description = "The CIDR of the public subnet."
  type        = string
}
variable "private_subnet_cidrs" {
  description = "List of CIDR's for the private subnets. For every CIDR a private subnet is created."
  type        = list(string)
}
variable "private_subnet_names" {
  description = "List of private subnet names. Length must match length of private_subnet_cidrs!"
  type        = list(string)
}
variable "public_subnet_name" {
  description = "The name of the public subnet."
  type        = string
  default     = "public-subnet"
}
variable "dependencies" {
  description = "Module dependencies."
  default     = []
}

# AWS
variable "aws_vpc_cidr" {
  description = "The CIDR of the VPC (e.g. 10.0.1.0/24). Required for AWS!"
  type        = string
  default     = ""
}
variable "aws_create_nat" {
  description = "Should a NAT Gateway created in the public subnet?"
  type        = bool
  default     = false
}
variable "nat_gateway_ip" {
  description = "Allocation ID of the IP that was manually created for the NAT."
  type        = string
  default     = ""
}

variable "aws_kubernetes_tagging" {
  description = "Tag the subnets so the managed Kubernetes service works"
  type        = bool
  default     = false
}
variable "aws_kubernetes_cluster_name" {
  description = "The name of the Kubernetes cluster. Need if you activated the Kubernetes tagging"
  type        = string
  default     = ""
}
variable "aws_additional_public_subnet_cidrs" {
  description = "List of CIDR used for additional publicc subnets. Used for e.g. AWS Load Balancer."
  type        = list(string)
  default     = []
}
variable "aws_additional_public_subnet_names" {
  description = "List of additional public subnet names. Length must match length of aws_additional_public_subnet_cidrs!"
  type        = list(string)
  default     = []
}

# LOCALS
locals {
  default_tags = {
    StageName   = var.stage_name
    ProjectName = var.project_name
    Name        = var.name
  }
  vpc_tags = var.aws_kubernetes_tagging ? map(
    "kubernetes.io/cluster/${var.aws_kubernetes_cluster_name}", "shared",
    "StageName", var.stage_name,
    "ProjectName", var.project_name,
    "Name", var.name,
  ) : local.default_tags
  public_subnet_tags = var.aws_kubernetes_tagging ? map(
    "kubernetes.io/cluster/${var.aws_kubernetes_cluster_name}", "shared",
    "kubernetes.io/role/elb", "1",
    "StageName", var.stage_name,
    "ProjectName", var.project_name,
    "Name", var.public_subnet_name,
    ) : {
    StageName   = var.stage_name
    ProjectName = var.project_name
    Name        = var.public_subnet_name
  }
}
