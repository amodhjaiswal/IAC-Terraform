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
          "alb.ingress.kubernetes.io/scheme"                        = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"                   = "ip"
          "alb.ingress.kubernetes.io/subnets"                       = join(",", var.public_subnet_ids)
          "alb.ingress.kubernetes.io/load-balancer-name"            = "k8s-${var.project_name}-${var.env_name}-backend"
          "alb.ingress.kubernetes.io/backend-protocol"              = "HTTP"
          "alb.ingress.kubernetes.io/target-group-attributes"       = "deregistration_delay.timeout_seconds=30,stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=300"
          "alb.ingress.kubernetes.io/listen-ports"                  = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
          "alb.ingress.kubernetes.io/certificate-arn"               = var.certificate_arn
          "alb.ingress.kubernetes.io/ssl-redirect"                  = "443"
          "alb.ingress.kubernetes.io/healthcheck-protocol"          = "HTTP"
          "alb.ingress.kubernetes.io/healthcheck-port"              = "traffic-port"
          "alb.ingress.kubernetes.io/healthcheck-interval-seconds"  = "15"
          "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"   = "5"
          "alb.ingress.kubernetes.io/success-codes"                 = "200-499"
          "alb.ingress.kubernetes.io/healthy-threshold-count"       = "2"
          "alb.ingress.kubernetes.io/unhealthy-threshold-count"     = "5"
          "alb.ingress.kubernetes.io/wafv2-acl-arn"                 = var.web_acl_arn
          "alb.ingress.kubernetes.io/tags"                          = "Environment=${var.env_name},ManagedBy=terraform,Application=backend"
          "alb.ingress.kubernetes.io/load-balancer-attributes"       = "access_logs.s3.enabled=true,access_logs.s3.bucket=${var.alb_logs_bucket_name},access_logs.s3.prefix=backend"
          "alb.ingress.kubernetes.io/redirect-http-to-https"        = "true"
          "alb.ingress.kubernetes.io/cors-enabled"                  = "true"
          "alb.ingress.kubernetes.io/cors-allow-origin"             = "*"
          "alb.ingress.kubernetes.io/cors-allow-methods"            = "GET, PUT, POST, DELETE, OPTIONS"
          "alb.ingress.kubernetes.io/cors-allow-headers"            = "*"

        }
      }

      spec = {
        ingressClassName = "alb"

        rules = [{
          host = local.backend_host
          http = {
            paths = [
              {
                path     = "/auth"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "auth-api-service"
                    port = { number = 3004 }
                  }
                }
              },
              {
                path     = "/admin"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "admin-api-service"
                    port = { number = 3005 }
                  }
                }
              },
              {
                path     = "/user"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "user-api-service"
                    port = { number = 3006 }
                  }
                }
              },
              {
                path     = "/notification"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "notif-api-service"
                    port = { number = 3007 }
                  }
                }
              },
              {
                path     = "/"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "notif-api-service"
                    port = { number = 3007 }
                  }
                }
              },
              {
                path     = "/cms"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "cms-api-service"
                    port = { number = 3008 }
                  }
                }
              },
              {
                path     = "/product"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "product-api-service"
                    port = { number = 3009 }
                  }
                }
              },
              {
                path     = "/order"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "order-api-service"
                    port = { number = 3010 }
                  }
                }
              },
              {
                path     = "/scheduler"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "scheduler-api-service"
                    port = { number = 3011 }
                  }
                }
              },
              {
                path     = "/productcore"
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "productcore-api-service"
                    port = { number = 3012 }
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
    command = "aws eks update-kubeconfig --region ${var.region} --name ${var.eks_cluster_name} && echo '${self.triggers.manifest}' | kubectl apply -f - --validate=false"
  }

  depends_on = [null_resource.production_cleanup]
}
