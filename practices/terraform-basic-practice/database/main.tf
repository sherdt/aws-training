# TODO
provider "aws" {
  shared_credentials_file = ""
  profile                 = ""
  region                  = "eu-central-1"
}

data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.module}/path/to/vpc/state/terraform.tfstate" # TODO
  }
}

resource "aws_db_subnet_group" "this" {
  # TODO
}

resource "aws_db_instance" "this" {
  # TODO
}

# TODO you need anything else?

/*
  TODO: You need to define outputs
*/
