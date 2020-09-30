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

locals {
  projectName = "prodyna-aws-training"
  name        = "${var.stage}-${local.projectName}-${terraform.workspace}-backend-insert-object"
  default_tags = {
    StageName   = var.stage
    ProjectName = local.projectName
    Name        = "${local.name}-${var.stage}-${terraform.workspace}"
  }
}
