output "eks" {
  value = aws_eks_cluster.self
}

output "update_kubeconfig" {
  value = "You can update your kubeconfig with the AWS CLI: aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${aws_eks_cluster.self.name} --profile XXX"
}

# TODO You need to configure the aws-auth config map in Kubernetes to allow other users to access the cluster. You can do that manually (kubectl apply) or try it via terraform.
