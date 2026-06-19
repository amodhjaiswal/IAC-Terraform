resource "null_resource" "metrics_server_servicemonitor_v3" {
  count = var.enable_metrics_server && var.create_monitoring ? 1 : 0

  triggers = {
    region          = var.region
    cluster_name    = var.cluster_name
    timestamp       = timestamp()
    manifest_content = yamlencode({
      apiVersion = "monitoring.coreos.com/v1"
      kind       = "ServiceMonitor"
      metadata = {
        name      = "metrics-server"
        namespace = "kube-system"
        labels = {
          "app.kubernetes.io/name" = "metrics-server"
        }
      }
      spec = {
        selector = {
          matchLabels = {
            "app.kubernetes.io/name" = "metrics-server"
          }
        }
        endpoints = [
          {
            port = "https"
            scheme = "https"
            tlsConfig = {
              insecureSkipVerify = true
            }
            bearerTokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"
          }
        ]
      }
    })
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name} --kubeconfig /tmp/kubeconfig-${var.cluster_name}
      echo '${yamlencode({
        apiVersion = "monitoring.coreos.com/v1"
        kind       = "ServiceMonitor"
        metadata = {
          name      = "metrics-server"
          namespace = "kube-system"
          labels = {
            "app.kubernetes.io/name" = "metrics-server"
          }
        }
        spec = {
          selector = {
            matchLabels = {
              "app.kubernetes.io/name" = "metrics-server"
            }
          }
          endpoints = [
            {
              port = "https"
              scheme = "https"
              tlsConfig = {
                insecureSkipVerify = true
              }
              bearerTokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"
            }
          ]
        }
      })}' | KUBECONFIG=/tmp/kubeconfig-${var.cluster_name} kubectl apply -f -
    EOT
  }

  depends_on = [
    helm_release.metrics_server,
    helm_release.prometheus,
    kubernetes_namespace.monitoring
  ]
}
