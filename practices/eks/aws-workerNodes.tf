# The launch configuration is like a template for every woker node
resource "aws_launch_configuration" "this" {
  # TODO
}

# The autoscaling group sets the autoscaling parameters and gets directly modified by the cluster autoscaler
resource "aws_autoscaling_group" "self" {
  # TODO

  tag {
    key                 = "kubernetes.io/cluster/${local.aws_cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.autoscaling_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    # Ignore changes to desired capacity because the autoscaler can change this value after deployment
    ignore_changes = [desired_capacity]
  }
}

# Special AWS kubernetes worker image.
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.this.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

resource "aws_iam_instance_profile" "node" {
  name = "${local.name}-instance-profile"
  role = aws_iam_role.node.name
}

/*
  Policies
*/
resource "aws_iam_role" "node" {
  name = "${local.name}-node"

  tags = local.default_tags

  assume_role_policy = <<ROLE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
ROLE
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

/*
  Security Groups
*/
resource "aws_security_group" "node" {
  name        = "${local.name}-node-security-group"
  description = "Security group for all nodes in the cluster"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_created.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

resource "aws_security_group_rule" "node_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
  to_port                  = 443
  type                     = "ingress"
}
