/*
  With a large module like this it is better to just include the configurations in the main.tf
*/

terraform {
  # TODO
}

provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_credentials.access_key
  secret_key = var.aws_credentials.secret_key
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

data "terraform_remote_state" "vpc" {
  # TODO
}
