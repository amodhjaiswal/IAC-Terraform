locals {
  grafana_host = "grafana-${var.env_name}.${var.domain}"
  argocd_host  = "argocd-${var.env_name}.${var.domain}"
  backend_host = "alb-${var.env_name}.${var.domain}"
  shared_group = "${var.project_name}-${var.env_name}-shared-lb"
}

resource "null_resource" "grafana_ingress" {
  count = var.create_manifests ? 1 : 0

  triggers = {
    ingress_name = "${var.project_name}-${var.env_name}-grafana"
    region       = var.region
    cluster_name = var.eks_cluster_name
    namespace    = "monitoring"
    manifest = jsonencode({
      apiVersion = "networking.k8s.io/v1"
      kind       = "Ingress"
      metadata = {
        name      = "${var.project_name}-${var.env_name}-grafana"
        namespace = "monitoring"
        annotations = {
          "alb.ingress.kubernetes.io/scheme"                       = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"                  = "ip"
          "alb.ingress.kubernetes.io/subnets"                      = join(",", var.public_subnet_ids)
          "alb.ingress.kubernetes.io/load-balancer-name"           = "k8s-${var.project_name}-${var.env_name}-alb"
          "alb.ingress.kubernetes.io/group.name"                   = local.shared_group
          "alb.ingress.kubernetes.io/backend-protocol"             = "HTTP"
          "alb.ingress.kubernetes.io/load-balancer-attributes"     = "access_logs.s3.enabled=true,access_logs.s3.bucket=${var.alb_logs_bucket_name},access_logs.s3.prefix=alb"
          "alb.ingress.kubernetes.io/target-group-attributes"      = "deregistration_delay.timeout_seconds=30,stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=300"
          "alb.ingress.kubernetes.io/listen-ports"                 = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
          "alb.ingress.kubernetes.io/certificate-arn"              = var.certificate_arn
          "alb.ingress.kubernetes.io/ssl-redirect"                 = "443"
          "alb.ingress.kubernetes.io/healthcheck-protocol"         = "HTTP"
          "alb.ingress.kubernetes.io/healthcheck-port"             = "traffic-port"
          "alb.ingress.kubernetes.io/healthcheck-path"             = "/api/health"
          "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
          "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
          "alb.ingress.kubernetes.io/success-codes"                = "200-499"
          "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
          "alb.ingress.kubernetes.io/wafv2-acl-arn"                 = var.web_acl_arn
          "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "5"
        }
      }
      spec = {
        ingressClassName = "alb"
        rules = [{
          host = local.grafana_host
          http = {
            paths = [{
              path     = "/"
              pathType = "Prefix"
              backend = {
                service = {
                  name = "grafana"
                  port = { number = 80 }
                }
              }
            }]
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