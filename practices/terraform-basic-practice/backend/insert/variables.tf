variable "stage" {
  type = string
  description = "Environment/stage ..."
}

locals {
  name = "ahs-lambda"
  default_tags = {
    team = "ahs"
  }
  lambdaName = "insertObject"
}