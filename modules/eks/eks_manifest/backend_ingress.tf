resource "null_resource" "backend_api_ingress" {
  count = var.create_manifests ? 1 : 0

  triggers = {
    ingress_name = "${var.project_name}-${var.env_name}-backend-api"
    region       = var.region
    cluster_name = var.eks_cluster_name
    namespace    = var.env_name
    manifest = jsonencode({
      apiVersion = "networking.k8s.io/v1"
      kind       = "Ingress"
      metadata = {
        name      = "${var.project_name}-${var.env_name}-backend-api"
        namespace = var.env_name
        annotations = {
          "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"        = "ip"
          "alb.ingress.kubernetes.io/subnets"            = join(",", var.public_subnet_ids)
          "alb.ingress.kubernetes.io/load-balancer-name" = "k8s-${var.project_name}-${var.env_name}-backend"
          "alb.ingress.kubernetes.io/backend-protocol"   = "HTTP"
          "alb.ingress.kubernetes.io/listen-ports"       = jsonencode([{ HTTP = 80 }])
          "alb.ingress.kubernetes.io/success-codes"      = "200-499"
          "alb.ingress.kubernetes.io/tags"               = "Environment=${var.env_name},ManagedBy=terraform,Application=backend"
        }
      }

      spec = {
        ingressClassName = "alb"

        rules = [{
          host = local.backend_host
          http = {
            paths = [
              {
                path     = "/admin"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "admin-api-service"
                    port = { number = 3020 }
                  }
                }
              },
              {
                path     = "/auth"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "auth-api-service"
                    port = { number = 3040 }
                  }
                }
              }
            ]
          }
        }]
      }
    })
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --region ${var.region} --name ${var.eks_cluster_name}
      echo '${self.triggers.manifest}' | kubectl apply -f - --validate=false
    EOT
  }

  depends_on = [null_resource.production_cleanup]
}
