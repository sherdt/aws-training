variable "aws_credentials" {
  type = object({
    access_key = string
    secret_key = string
  })

  description = "AWS credentials used for terraform."
}

locals {
  stageName   = "prod"
  projectName = "prodyna-aws-training"
  name        = "${local.stageName}-${local.projectName}-${terraform.workspace}-s3-frontend"
  bucketName  = "example.prodyna-aws-training.de"
  terraformUserARN = "arn:aws:iam::190822135932:user/terraform"
  default_tags = {
    StageName   = local.stageName
    ProjectName = local.projectName
    Name        = "${local.name}-${local.stageName}-${terraform.workspace}"
  }
}
