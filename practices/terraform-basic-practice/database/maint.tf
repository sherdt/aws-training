provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_credentials.access_key # TODO
  secret_key = var.aws_credentials.secret_key # TODO
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

/*
  TODO: You need to define outputs
*/
