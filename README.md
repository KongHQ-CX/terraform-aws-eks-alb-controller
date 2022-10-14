# terraform-aws-eks-alb-controller

A terraform module for provisioning an ALB controller to an EKS cluster

## Usage

### Using module defaults

The following will create an ALB controller in an EKS cluster

```HCL
module "alb-controller" {
  source            = "srb3/eks-alb-controller/aws"
  oidc_provider_arn = module.cluster-1.0.oidc_provider_arn
  region            = var.region
  vpc_id            = module.vpc.vpc_id
  cluster_name      = "cluster-1-${local.name}"
}
```

## Misc

This module was inspired by this blog [post](https://andrewtarry.com/posts/terraform-eks-alb-setup/)

