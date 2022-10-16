locals {
  cluster_cp     = try(module.cluster-1.0.cluster_id, "cluster-not-created")
  cluster_cp_arn = try(module.cluster-1.0.cluster_arn, "cluster-not-created")
  config_cp      = "aws eks update-kubeconfig --name ${local.cluster_cp}"
  context_cp     = "kubectl config use-context ${local.cluster_cp_arn}"
}

output "kubeconfigs" {
  value = [
    local.config_cp,
  ]
}

output "contexts" {
  value = [
    local.context_cp,
  ]
}
