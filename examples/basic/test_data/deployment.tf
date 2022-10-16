resource "kubernetes_manifest" "deployment_nginx_deploy_blue" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "labels" = {
        "run" = "nginx"
      }
      "name" = "nginx-deploy-blue"
      "namespace" = "nginx-blue"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "run" = "nginx-blue"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "run" = "nginx-blue"
          }
        }
        "spec" = {
          "containers" = [
            {
              "image" = "nginx"
              "name" = "nginx"
              "resources" = {
                "limits" = {
                  "cpu" = "250m"
                  "memory" = "256Mi"
                }
                "requests" = {
                  "cpu" = "250m"
                  "memory" = "256Mi"
                }
              }
              "volumeMounts" = [
                {
                  "mountPath" = "/usr/share/nginx/html"
                  "name" = "webdata"
                },
              ]
            },
          ]
          "initContainers" = [
            {
              "command" = [
                "/bin/sh",
                "-c",
                "echo \"<h1>I am <font color=blue>BLUE</font></h1>\" > /webdata/index.html",
              ]
              "image" = "busybox"
              "name" = "web-content"
              "volumeMounts" = [
                {
                  "mountPath" = "/webdata"
                  "name" = "webdata"
                },
              ]
            },
          ]
          "volumes" = [
            {
              "emptyDir" = {}
              "name" = "webdata"
            },
          ]
        }
      }
    }
  }
}
