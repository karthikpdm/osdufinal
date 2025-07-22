terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.98.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# provider "aws" {
#   region = var.outpost_region
# }

# data "aws_eks_cluster" "osdu_eks_cluster" {
#   name = var.eks_cluster_name
#   depends_on = [
#     aws_eks_cluster.osdu_eks_cluster
#   ]
# }

# data "aws_eks_cluster_auth" "osdu_eks_cluster_auth" {
#   name = var.eks_cluster_name
#   depends_on = [
#     aws_eks_cluster.osdu_eks_cluster
#   ]
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.osdu_eks_cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.osdu_eks_cluster.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.osdu_eks_cluster_auth.token
# }

# provider "helm" {
#   kubernetes = {
#     host                   = data.aws_eks_cluster.osdu_eks_cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.osdu_eks_cluster.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.osdu_eks_cluster_auth.token
#   }
# }



provider "aws" {
  region = "us-east-1"
}

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# FIXED: Add the missing EKS cluster data source
data "aws_eks_cluster" "bsp_eks" {
  name = aws_eks_cluster.osdu_eks_cluster_regional.name
  depends_on = [aws_eks_cluster.osdu_eks_cluster_regional]
}

# EKS cluster authentication data source
data "aws_eks_cluster_auth" "bsp_eks" {
  name = aws_eks_cluster.osdu_eks_cluster_regional.name
  depends_on = [aws_eks_cluster.osdu_eks_cluster_regional]
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.bsp_eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.bsp_eks.certificate_authority[0].data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.osdu_eks_cluster_regional.name, "--region", "us-east-1"]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.bsp_eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.bsp_eks.certificate_authority[0].data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.osdu_eks_cluster_regional.name, "--region", "us-east-1"]
    }
  }
}




