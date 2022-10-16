resource "kubernetes_manifest" "ingress_nginx_blue" {
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind" = "Ingress"
    "metadata" = {
      "annotations" = {
        "alb.ingress.kubernetes.io/group.name" = "ingress-demo"
        "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
        "alb.ingress.kubernetes.io/healthcheck-port" = "traffic-port"
        "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
        "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" = "5"
        "alb.ingress.kubernetes.io/healthy-threshold-count" = "2"
        "alb.ingress.kubernetes.io/scheme" = "internet-facing"
        "alb.ingress.kubernetes.io/success-codes" = "200"
        "alb.ingress.kubernetes.io/target-type" = "instance"
        "alb.ingress.kubernetes.io/unhealthy-threshold-count" = "2"
        "kubernetes.io/ingress.class" = "alb"
      }
      "name" = "nginx-blue"
      "namespace" = "nginx-blue"
    }
    "spec" = {
      "rules" = [
        {
          "host" = "blue.yallalabs.com"
          "http" = {
            "paths" = [
              {
                "backend" = {
                  "service" = {
                    "name" = "nginx-blue"
                    "port" = {
                      "number" = 80
                    }
                  }
                }
                "path" = "/"
                "pathType" = "Prefix"
              },
            ]
          }
        },
      ]
    }
  }
}
