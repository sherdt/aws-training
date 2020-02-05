# EKS
resource "aws_eks_cluster" "this" {

  # TODO

  tags = local.default_tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.service_policy
  ]
}

/*
  This config map joins the worker nodes.

  TODO: Add every IAM user in your team to this config map. E.g.:
    - userarn: arn:aws:iam::11122223333:user/example-user
      username: example-user
      groups:
        - system:masters
*/
resource "kubernetes_config_map" "join_worker_nodes" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<ROLES
- rolearn: ${aws_iam_role.node.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
ROLES
  }

  lifecycle {
    # Ignore changes to data to prevent overwriting cluster roles/user added after the initial deployment
    ignore_changes = [data]
  }

  depends_on = [aws_iam_role.node, aws_eks_cluster.this, data.aws_eks_cluster_auth.cluster_auth, null_resource.endpoint_waiter]
}

/*
  Cluster Role
*/
resource "aws_iam_role" "cluster" {
  name = "${local.stageName}-${terraform.workspace}-cluster-policy"

  tags               = local.default_tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster.name
}

/*
  Security Groups
*/
resource "aws_security_group" "cluster" {
  name        = "${local.name}-security-group"
  description = "Cluster communication with worker nodes"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_created.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

resource "aws_security_group_rule" "cluster_workstation_ingress" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster.id
  to_port           = 443
  type              = "ingress"
}

# We need the cluster auth. context to apply config maps
data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.this.name
}

// wait until the cluster endpoint is ready
resource "null_resource" "endpoint_waiter" {
  triggers = {
    endpoint = aws_eks_cluster.this.endpoint
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      ENDPOINT = replace(aws_eks_cluster.this.endpoint, "https://", "")
    }

    command = <<EOF
count=10
interval=30
while [[ $count -gt 0 ]]; do
  if nc -z "$ENDPOINT" 443; then
    exit 0
  fi
  count=$((count-1))
  if [[ $count -eq 0 ]]; then
    exit 1
  fi
  sleep $interval
done
EOF
  }
}
