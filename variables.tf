variable "oidc_provider_arn" {
  description = "The arn of an EKS's oidc provider"
  type        = string
}

variable "create_role" {
  description = "Should we create external DNS IAM roles"
  type        = bool
  default     = true
}

variable "create_service_account" {
  description = "Should we create external DNS service account"
  type        = bool
  default     = true
}

variable "create_deployment" {
  description = "Should we create the external DNS IAM roles"
  type        = bool
  default     = true
}

variable "service_account" {
  description = "The name of the service account to use for external DNS"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "The name of the Kubernetes namespace to use for the ALB controller"
  type        = string
  default     = "kube-system"
}

variable "chart_version" {
  description = "The version of the chart to use"
  type        = string
  default     = "1.4.5"
}

variable "tags" {
  description = "A map of tags to attach to the resources created by this module"
  type        = map(any)
  default     = {}
}

variable "region" {
  description = "The region of the Kubernetes cluster to use for the ALB controller"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID of the kubernetes cluster to use for the ALB controller"
  type        = string
}
