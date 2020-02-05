# You can use my Cluster Autoscaler module or try it yourself
module "autoscaler" {
  source = "github.com/DennisCreutz/terraform-modules/service/clusterAutoscaler"

  cluster_name          = aws_eks_cluster.this.name
  worker_node_role_name = aws_iam_role.node.name

  autoscaling_desired_size = local.autoscaling_desired_size
  autoscaling_max_size     = local.autoscaling_max_size
  autoscaling_min_size     = local.autoscaling_min_size

  scaling_cooldown            = 60
  skip_nodes_with_system_pods = false

  create_autoscaler = true
}
