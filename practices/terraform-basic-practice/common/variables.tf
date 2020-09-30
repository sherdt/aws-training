variable "team" {
  default = "ahs"
}

variable "stage" {
  type = string
  description = "Environment/stage ..."
}

locals {
  name = "${var.team}-lambda"
  default_tags = {
    team = var.team
  }
}