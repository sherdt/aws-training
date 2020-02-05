variable "aws_credentials" {
  type = object({
    access_key = string
    secret_key = string
  })

  description = "AWS credentials used for terraform."
}

locals {
  stageName   = "prod"
  projectName = "prodyna-aws-training"
  name        = "${local.stageName}-${local.projectName}-${terraform.workspace}-backend-kubernetes"
  default_tags = {
    StageName   = local.stageName
    ProjectName = local.projectName
    Name        = "${local.name}-${local.stageName}-${terraform.workspace}"
  }

  aws_cluster_name   = local.name
  autoscaler_sa_name = "cluster-autoscaler"
  autoscaler_version = "1.16.3"
  autoscaling_tags = merge(local.default_tags, {
    "k8s.io/cluster-autoscaler/enabled"                   = ""
    "k8s.io/cluster-autoscaler/${local.aws_cluster_name}" = ""
  })

  worker_nodes_instance_size = "t3.medium"
  autoscaling_desired_size   = 2
  autoscaling_max_size       = 3
  autoscaling_min_size       = 1

  # EKS currently documents this required userdata for EKS worker nodes to
  # properly configure Kubernetes applications on the EC2 instance.
  # We implement a Terraform local here to simplify Base64 encoding this
  # information into the AutoScaling Launch Configuration.
  # More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
  node_userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.this.endpoint}' --b64-cluster-ca '${aws_eks_cluster.this.certificate_authority.0.data}' '${local.aws_cluster_name}'
USERDATA
}
