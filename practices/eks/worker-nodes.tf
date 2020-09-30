# With multiple node groups the cluster autoscaler can choose between multiple instance types and choose the best match.
# TODO Create 1 node groups with 1/3/1 (min/max/des) "t3.small"
resource "aws_eks_node_group" "node_group" {
  count = length(var.node_groups)

  cluster_name = aws_eks_cluster.eks.name

  disk_size = var.node_groups[count.index].disk_size

  tags = {
    stageName   = var.stage
    projectName = local.projectName
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_cni_policy,
    aws_iam_role_policy_attachment.aws_eks_worker_node_policy,
    aws_iam_role_policy_attachment.ec2_read_only
  ]

  lifecycle {
    # On update create the new node group before destroying the old one. Needed to prevent errors.
    create_before_destroy = true
    # The cluster autoscaler (in Kubernetes) will change this value. We need to ignore this changes on apply.
    ignore_changes = [scaling_config[0].desired_size]
  }

  node_group_name = "ahs-node-group"
  node_role_arn = aws_iam_role.eks_nodes.arn
  subnet_ids = data.terraform_remote_state.vpc.outputs.aws_private_subnets_ids
  scaling_config {
    max_size      = var.node_groups[count.index].max_size
    min_size      = var.node_groups[count.index].min_size
    desired_size  = var.node_groups[count.index].initial_size
  }
}

# Role and policies needed for the worker nodes
resource "aws_iam_role" "eks_nodes" {
  name               = "${aws_eks_cluster.eks.name}-worker"
  assume_role_policy = data.aws_iam_policy_document.assume_workers.json
}
data "aws_iam_policy_document" "assume_workers" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy_attachment" "aws_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}
resource "aws_iam_role_policy_attachment" "aws_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}
resource "aws_iam_role_policy_attachment" "ec2_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}
resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${var.stage}-cluster-autoscaler-${terraform.workspace}"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}
resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}
