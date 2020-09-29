variable "team" {
  default = "ahs"
}

locals {
  name = "${var.team}-lambda"
  default_tags = {
    team = var.team
  }
}