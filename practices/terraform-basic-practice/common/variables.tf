variable "team" {
  default = "ahs"
}


locals {
  name = "ahs-lambda"
  default_tags = {
    team = "ahs"
  }
}