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
  name = "s3-frontend"
}
