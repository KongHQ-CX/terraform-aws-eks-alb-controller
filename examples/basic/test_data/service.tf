resource "kubernetes_manifest" "service_nginx_blue" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "nginx-blue"
      "namespace" = "nginx-blue"
    }
    "spec" = {
      "ports" = [
        {
          "port" = 80
          "protocol" = "TCP"
          "targetPort" = 80
        },
      ]
      "selector" = {
        "run" = "nginx-blue"
      }
      "type" = "NodePort"
    }
  }
}
