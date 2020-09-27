variable "stage" {
  type = string
}
variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health."
  type        = number
  default     = 300
}
variable "enable_asg_metrics" {
  description = "Enable metrics for the autoscaling group."
  type        = bool
  default     = true
}
variable "scaling_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes before another scaling activity can start."
  type        = number
  default     = 300
}
variable "scale_down_utilization_threshold" {
  description = "Node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down."
  type        = string
  default     = "0.5"
}
variable "skip_nodes_with_system_pods" {
  description = "Cluster autoscaler will not terminate nodes running pods in the kube-system namespace."
  type        = bool
  default     = true
}
variable "autoscaler_version" {
  description = "Version of the Kubernetes cluster autoscaler"
  type        = string
  default     = "1.17.1"
}
variable "eks_remote_key" {
  description = "The key to the EKS remote Terraform state."
  type        = string
}
