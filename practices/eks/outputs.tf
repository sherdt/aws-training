output "eks_created" {
  value = aws_eks_cluster.this
}
output "update_kubeconfig" {
  value = "You can update your kubeconfig with the AWS CLI: aws eks --region eu-central-1 update-kubeconfig --name ${local.aws_cluster_name}"
}
output "warning" {
  value = "WARNING: If you deploy a Kubernetes LoadBalancer then the resource is not managed by Terraform!"
}
