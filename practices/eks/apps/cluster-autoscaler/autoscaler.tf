resource "kubernetes_role" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
  }

  rule {
    api_groups = [
      "",
    ]

    resources = [
      "configmaps",
    ]

    verbs = [
      "create",
    ]
  }
  rule {
    api_groups = [
      "",
    ]

    resources = [
      "configmaps",
    ]

    resource_names = [
      "cluster-autoscaler-status",
    ]

    verbs = [
      "delete",
      "get",
      "update",
    ]
  }
}

resource "kubernetes_role_binding" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    name      = kubernetes_role.cluster_autoscaler.metadata[0].name
    kind      = "Role"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cluster_autoscaler.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_service_account" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
  }

  automount_service_account_token = "true"
}

resource "kubernetes_cluster_role" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["events", "endpoints"]
    verbs      = ["create", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods/eviction"]
    verbs      = ["create"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods/status"]
    verbs      = ["update"]
  }
  rule {
    api_groups     = [""]
    resources      = ["endpoints"]
    resource_names = ["cluster-autoscaler"]
    verbs          = ["get", "update"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["watch", "list", "get", "update"]
  }
  rule {
    verbs      = ["watch", "list", "get"]
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "csinodes"]
  }
  rule {
    api_groups = [""]
    resources = [
      "pods",
      "services",
      "replicationcontrollers",
      "persistentvolumeclaims",
      "persistentvolumes",
    ]
    verbs = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["daemonsets"]
    verbs      = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["watch", "list"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["replicasets", "statefulsets", "daemonsets"]
    verbs      = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["create"]
  }
  rule {
    api_groups     = ["coordination.k8s.io"]
    resources      = ["leases"]
    resource_names = ["cluster-autoscaler"]
    verbs          = ["get", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    name      = kubernetes_cluster_role.cluster_autoscaler.metadata[0].name
    kind      = "ClusterRole"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cluster_autoscaler.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"

    labels = {
      "app" = "cluster-autoscaler"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cluster-autoscaler"
      }
    }

    template {
      metadata {
        labels = {
          app = "cluster-autoscaler"
        }
      }

      spec {
        automount_service_account_token = true
        service_account_name            = kubernetes_service_account.cluster_autoscaler.metadata[0].name

        container {
          command = [
            "./cluster-autoscaler",
            "--v=2",
            "--cloud-provider=aws",
            "--skip-nodes-with-local-storage=false",
            "--expander=least-waste",
            "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,kubernetes.io/cluster/${data.terraform_remote_state.eks.outputs.eks.name}",
            "--scale-down-delay-after-add=${var.scaling_cooldown}s",
            "--scale-down-delay-after-delete=${var.scaling_cooldown}s",
            "--scale-down-delay-after-failure=${var.scaling_cooldown}s",
            "--scale-down-unneeded-time=${var.scaling_cooldown}s",
            "--scale-down-utilization-threshold=${var.scale_down_utilization_threshold}",
            "--skip-nodes-with-system-pods=${var.skip_nodes_with_system_pods}",
          ]

          resources {
            limits {
              cpu    = "100m"
              memory = "300Mi"
            }
            requests {
              cpu    = "100m"
              memory = "300Mi"
            }
          }

          image             = "gcr.io/google-containers/cluster-autoscaler:v${var.autoscaler_version}"
          image_pull_policy = "Always"

          name = "cluster-autoscaler"

          volume_mount {
            name       = "ssl-certs"
            mount_path = "/etc/ssl/certs/ca-certificates.crt"
            read_only  = "true"
          }
        }
        volume {
          name = "ssl-certs"
          host_path {
            path = "/etc/ssl/certs/ca-bundle.crt"
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_cluster_role.cluster_autoscaler,
    kubernetes_role.cluster_autoscaler,
    kubernetes_service_account.cluster_autoscaler
  ]
}
