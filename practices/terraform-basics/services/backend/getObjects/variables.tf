variable "aws_credentials" {
  type = object({
    access_key = string
    secret_key = string
  })

  description = "AWS credentials used for terraform."
}

variable "db_credentials" {
  type = object({
    user = string
    pw = string
  })

  description = "Database credntials."
}

locals {
  stageName = "prod"
  projectName = "prodyna-aws-training"
  name = "${local.stageName}-${local.projectName}-${terraform.workspace}-backend-get-objects"
  lambdaName = "getObjects"
  default_tags = {
    StageName   = local.stageName
    ProjectName = local.projectName
    Name        = "${local.name}-${local.stageName}-${terraform.workspace}"
  }
}
