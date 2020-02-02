variable "aws_credentials" {
  type = object({
    access_key = string
    secret_key = string
  })

  description = "AWS credentials used for terraform."
}

locals {
  stageName = "prod"
  projectName = "prodyna-aws-training"
  name = "terraform-statemanager"
  default_tags = {
    StageName   = local.stageName
    ProjectName = local.projectName
    Name        = "${local.name}-${local.stageName}-${terraform.workspace}"
  }
  store_name = "${local.name}-store-123812902"
  lock_database_name = "${local.name}-lock-db"
}
