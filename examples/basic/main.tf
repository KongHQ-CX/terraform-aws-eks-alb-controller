########### Providers ############################

provider "aws" {
  region = var.region
}


########### Data and misc ########################

resource "random_string" "env" {
  length  = 4
  special = false
  upper   = false
}

locals {
  name         = "${var.name}-${random_string.env.result}"
  cluster_name = "cluster-1-${local.name}"
  tags = merge(
    var.tags,
    {
      "X-Contact"     = var.contact
      "X-Environment" = "kong-mesh-accelerator"
    },
  )
}
########### VPC ##################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = "10.99.0.0/18"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets  = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
  private_subnets = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]
  intra_subnets   = ["10.99.6.0/24", "10.99.7.0/24", "10.99.8.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"             = 1
  }
  tags = local.tags
}

resource "aws_security_group" "eks" {
  name        = "${local.cluster_name} eks cluster"
  description = "Allow traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "World"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({
    Name = "EKS ${local.cluster_name}",
    "kubernetes.io/cluster/${local.cluster_name}" : "owned"
  }, local.tags)
}

locals {
  vpc_id = module.vpc.vpc_id
}


data "aws_vpc" "this" {
  id = module.vpc.vpc_id
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  tags = {
    Name = "*private*"
  }
}

########### Data and misc ########################

data "aws_eks_cluster" "cluster-1" {
  name = module.cluster-1.0.cluster_id
}

data "aws_eks_cluster_auth" "cluster-1" {
  name = module.cluster-1.0.cluster_id
}

########### Global CP Cluster ####################

provider "kubernetes" {
  alias                  = "cluster_1"
  host                   = data.aws_eks_cluster.cluster-1.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster-1.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster-1.token
}

provider "helm" {
  alias = "cluster_1"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster-1.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster-1.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster-1.token
  }
}

module "cluster-1" {
  count = var.cluster_1_create ? 1 : 0
  providers = {
    kubernetes = kubernetes.cluster_1
  }
  source                                = "terraform-aws-modules/eks/aws"
  version                               = "18.29.0"
  cluster_name                          = local.cluster_name
  cluster_version                       = var.eks_kubernetes_version
  cluster_endpoint_private_access       = true
  cluster_endpoint_public_access        = true
  enable_irsa                           = true
  cluster_additional_security_group_ids = [aws_security_group.eks.id]


  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_groups = {
    global_cp = {
      create_launch_template = false
      launch_template_name   = ""
      disk_size              = 50
      instance_types         = [var.eks_instance_size]
      min_size               = var.eks_min_size
      max_size               = var.eks_max_size
      desired_size           = var.eks_desired_size
      vpc_security_group_ids = [aws_security_group.eks.id]
      tags                   = local.tags
    }
  }
  cluster_tags = local.tags
  tags         = local.tags
}

module "cluster-1-alb" {
  source = "../../"
  providers = {
    kubernetes = kubernetes.cluster_1
    helm       = helm.cluster_1
  }
  oidc_provider_arn = module.cluster-1.0.oidc_provider_arn
  cluster_name      = local.cluster_name
  service_account   = "aws-load-balancer-controller"
  namespace         = "kube-system"
  region            = var.region
  vpc_id            = module.vpc.vpc_id
  tags              = local.tags
  depends_on        = [module.cluster-1]
}

########### Test the controller ##################

resource "kubernetes_namespace" "namespace_nginx_blue" {
  provider = kubernetes.cluster_1
  metadata {
    name = "nginx-blue"
  }
  depends_on = [module.cluster-1, module.cluster-1-alb]
}

module "nginx-deploy-blue" {
  source  = "srb3/simple-deployment/kubernetes"
  version = "0.0.7"
  providers = {
    kubernetes = kubernetes.cluster_1
  }
  namespace = kubernetes_namespace.namespace_nginx_blue.metadata[0].name
  name      = "nginx-blue"
  image     = "nginx"
  resource_requests = {
    cpu    = "250m"
    memory = "256Mi"
  }
  resource_limits = {
    cpu    = "250m"
    memory = "256Mi"
  }

  ports = {
    "http" = {
      port           = 80
      protocol       = "TCP"
      container_port = 80
    }
  }
  config_map_volumes = [
    {
      name       = "webdata",
      mount_path = "/usr/share/nginx/html",
      read_only  = true,
      data       = { "index.html" = "<h1>I am <font color=blue>BLUE</font></h1>" }
    }
  ]
  service_type = "NodePort"
  depends_on   = [module.cluster-1, module.cluster-1-alb, kubernetes_namespace.namespace_nginx_blue]
}

resource "kubernetes_ingress_v1" "nginx-blue" {
  provider = kubernetes.cluster_1
  metadata {
    name      = "nginx-blue"
    namespace = kubernetes_namespace.namespace_nginx_blue.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "instance"
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\":80}]"
      "kubernetes.io/ingress.class"                = "alb"
    }
  }
  spec {
    rule {
      host = var.hostname
      http {
        path {
          path = "/"
          backend {
            service {
              name = "nginx-blue"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [module.cluster-1, module.cluster-1-alb, module.nginx-deploy-blue]
}
