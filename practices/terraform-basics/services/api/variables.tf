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
  name = "${local.stageName}-${local.projectName}-${terraform.workspace}-api-gateway"
  default_tags = {
    StageName   = local.stageName
    ProjectName = local.projectName
    Name        = local.name
  }
}
