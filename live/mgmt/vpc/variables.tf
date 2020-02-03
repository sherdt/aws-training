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
  name = "${local.stageName}-${local.projectName}-${terraform.workspace}-vpc"
  default_tags = {
    StageName   = local.stageName
    ProjectName = local.projectName
    Name        = local.name
  }
  create_nat = true
  vpc_cidr              = "10.0.0.0/16"
  private_subnet_1_cidr = "10.0.0.0/19"
  private_subnet_2_cidr = "10.0.32.0/19"
  private_subnet_3_cidr = "10.0.64.0/19"
  public_subnet_cidr    = "10.0.96.0/19"
}
