variable "oidc_provider_arn" {
  description = "The arn of an EKS's oidc provider"
  type        = string
}

variable "region" {
  description = "The aws region of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID of the EKS's VPC"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS"
  type        = string
}
