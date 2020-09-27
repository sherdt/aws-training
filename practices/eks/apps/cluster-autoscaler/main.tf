terraform {
  # TODO
}

# TODO
provider "aws" {
  shared_credentials_file = ""
  profile                 = ""
  region                  = "eu-central-1"
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = data.terraform_remote_state.eks.outputs.eks.name
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.eks.endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  load_config_file       = false
}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    # TODO
  }
}

