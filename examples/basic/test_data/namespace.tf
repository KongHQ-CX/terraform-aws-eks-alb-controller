resource "kubernetes_manifest" "namespace_nginx_blue" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Namespace"
    "metadata" = {
      "name" = "nginx-blue"
    }
  }
}
