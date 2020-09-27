variable "stage" {
  type = string
}
variable "node_groups" {
  type = list(object({
    max_size      = number
    min_size      = number
    initial_size  = number
    instance_type = string
    disk_size     = number
  }))

  description = "List of node group configurations."
}

variable "vpc_remote_key" {
  description = "The key to the VPC remote Terraform state."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

locals {
  projectName = "prodyna-aws-training"
  name        = "${var.stage}-${local.projectName}-${terraform.workspace}-backend-insert-object"
  default_tags = {
    StageName   = var.stage
    ProjectName = local.projectName
    Name        = "${local.name}-${var.stage}-${terraform.workspace}"
  }
}
