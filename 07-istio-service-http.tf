# This script will install the IstioBase, Istiod and Istio gateway

# Below is the normal helm command but we will use terraform the below command is only for information and not used.
# helm repo add istio https://istio-release.storage.googleapis.com/charts
# helm repo update
# helm install demo-eks-istio-base -n istio-system --create-namespace istio/base --set global.istioNamespace=istio-system
# helm install demo-eks-istiod -n istio-system --create-namespace istio/istiod --set telemetry.enabled=true --set global.istioNamespace=istio-system
# helm install demo-eks-istio-gateway -n istio-system --create-namespace istio/gateway

# Create namespace for istio base and istiod
# resource "kubernetes_namespace" "istio_namespace" {
#   metadata {
#     name = "istio-system"
#   }
# }

# # Create namespace for istio gateway
# resource "kubernetes_namespace" "istio_gateway_namespace" {
#   metadata {
#     name = "istio-gateway"
#   }
# }

# # updating the kubeclt config before provisioning istio to add the sidecar proxy
# resource "null_resource" "update_kubeconfig" {
#   provisioner "local-exec" {
#     command = "echo 'Updating kubeconfig...' && aws eks update-kubeconfig --region ${var.outpost_region} --name ${var.eks_cluster_name}"
#   }

#   triggers = {
#     cluster_name = var.eks_cluster_name
#     region       = var.outpost_region
#   }
#   depends_on = [aws_eks_cluster.osdu_eks_cluster]
# }

# # Adding the side car proxy to all the services present in 'default' namespace.
# resource "null_resource" "label_default_namespace" {
#   provisioner "local-exec" {
#     command = "echo 'Labeling default namespace for Istio sidecar injection...' && kubectl label namespace default istio-injection=enabled --overwrite"
#   }

#   depends_on = [
#     null_resource.update_kubeconfig,
#     helm_release.osdu_istio_istiod
#   ]
# }

# # Creating the Istio Base
# resource "helm_release" "osdu_istio_base" {
#   name = "osdu_istio_base"
#   /* Using the downloaded chart to maintain version consistency */
#   # repository = "https://istio-release.storage.googleapis.com/charts"
#   # chart      = "base"
#   chart     = "${path.module}/charts/${var.tar_istio_base}"
#   namespace = kubernetes_namespace.istio_namespace.metadata[0].name
#   version   = "1.21.0"
#   depends_on = [
#     kubernetes_namespace.istio_namespace,
#     aws_eks_addon.osdu_csi_addon
#   ]
# }

# # Deploying the Istiod 
# resource "helm_release" "osdu_istio_istiod" {
#   name = "osdu_istio_istiod"
#   /* Using the downloaded chart to maintain version consistency */
#   # repository = "https://istio-release.storage.googleapis.com/charts"
#   # chart      = "istiod"
#   chart     = "${path.module}/charts/${var.tar_istiod}"
#   namespace = kubernetes_namespace.istio_namespace.metadata[0].name
#   version   = "1.21.0"

#   values = [
#     yamlencode({
#       global = {
#         proxy = {
#           autoInject = "enabled"
#         }
#       }
#       pilot = {
#         nodeSelector = {
#           "node-role" = "osdu_istio_node"
#         }
#         tolerations = [
#           {
#             key      = "role"
#             operator = "Equal"
#             value    = "osdu_istio_node"
#             effect   = "NoSchedule"
#           }
#         ]
#       }
#     })
#   ]
#   wait    = true
#   timeout = 600
#   depends_on = [
#     helm_release.osdu_istio_base
#   ]
# }

# # Deploying the Istio Ingress Gateway 
# resource "helm_release" "istio_ingressgateway" {
#   name = "istio-ingressgateway"
#   /* Using the downloaded chart to maintain version consistency */
#   # repository = "https://istio-release.storage.googleapis.com/charts"
#   # chart      = "gateway"
#   chart     = "${path.module}/charts/${var.tar_istio_gateway}"
#   namespace = kubernetes_namespace.istio_gateway_namespace.metadata[0].name
#   version   = "1.21.0"

#   values = [
#     yamlencode({

#       image = {
#         repository = "docker.io/istio/proxyv2"
#         tag        = "1.21.0"
#         pullPolicy = "IfNotPresent"
#       }

#       service = {
#         type = "LoadBalancer"
#         ports = [
#           {
#             port       = 80
#             targetPort = 8080
#             name       = "http2"
#           },
#           {
#             port       = 443
#             targetPort = 8443
#             name       = "https"
#           }
#         ]
#       }

#       nodeSelector = {
#         "node-role" = "osdu_istio_node"
#       }

#       tolerations = [
#         {
#           key      = "role"
#           operator = "Equal"
#           value    = "osdu_istio_node"
#           effect   = "NoSchedule"
#         }
#       ]

#     })
#   ]
#   wait    = true
#   timeout = 600
#   depends_on = [
#     helm_release.osdu_istio_istiod,
#     kubernetes_namespace.istio_gateway_namespace
#   ]
# }


# resource "null_resource" "wait_for_ingressgateway" {
#   depends_on = [helm_release.istio_ingressgateway]
#   provisioner "local-exec" {
#     command = "echo 'Waiting for istio-ingressgateway to become available...'"
#   }
# }

# data "kubernetes_service" "istio_gateway" {
#   metadata {
#     name      = "istio-ingressgateway"
#     namespace = "istio-gateway"
#   }
#   depends_on = [
#     null_resource.wait_for_ingressgateway,
#     helm_release.istio_ingressgateway
#   ]
# }

# locals {
#   istio_gateway_domain = try(
#     data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname,
#     try(
#       data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].ip,
#       null
#     )
#   )
# }

# # Creating the service gateway. This is very important for OSDU microservices as all uses service gateway.
# resource "null_resource" "osdu_service_gateway" {
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = <<-EOT
#       cat <<EOF | kubectl apply -f -
# apiVersion: networking.istio.io/v1beta1
# kind: Gateway
# metadata:
#   name: service-gateway
#   namespace: default
# spec:
#   selector:
#     istio: ingressgateway
#   servers:
#     - port:
#         number: 80
#         name: http
#         protocol: HTTP
#       hosts:
#         - osdu.${local.istio_gateway_domain}
#       tls:
#         httpsRedirect: true
#     - port:
#         number: 443
#         name: https
#         protocol: HTTPS
#       tls:
#         mode: SIMPLE
#         credentialName: osdu-ingress-tls
#       hosts:
#         - osdu.${local.istio_gateway_domain}
# EOF
#     EOT
#   }

#   depends_on = [
#     helm_release.istio_ingressgateway,
#     kubernetes_secret.osdu_tls_secret,
#     null_resource.update_kubeconfig,
#     null_resource.wait_for_ingressgateway
#   ]
# }

# output "istio_ingress_gateway_dns" {
#   description = "DNS name of the Istio ingress gateway service"
#   value       = data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname
# }

# output "domain-name" {
#   value      = local.istio_gateway_domain
#   depends_on = [helm_release.istio_ingressgateway]
# }

# output "istio_gateway_dns" {
#   value      = data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname
#   depends_on = [helm_release.istio_ingressgateway]
# }















# Create namespace for Istio system
resource "kubernetes_namespace" "istio_namespace" {
  metadata {
    name = "istio-system"
  }

  depends_on = [
    kubernetes_config_map_v1.aws_auth,
    time_sleep.wait_for_auth
  ]
}

# Create namespace for Istio gateway
resource "kubernetes_namespace" "istio_gateway_namespace" {
  metadata {
    name = "istio-gateway"
  }

  depends_on = [
    kubernetes_config_map_v1.aws_auth,
    time_sleep.wait_for_auth
  ]
}

# Updating the kubectl config before provisioning Istio to add the sidecar proxy
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "echo 'Updating kubeconfig...' && aws eks update-kubeconfig --region ${var.aws_region} --name ${var.eks_cluster_name}"
  }

  triggers = {
    cluster_name = var.eks_cluster_name
    region       = var.aws_region
  }
  
  depends_on = [aws_eks_cluster.osdu_eks_cluster_regional]
}

# Adding the sidecar proxy to all the services present in 'default' namespace
resource "null_resource" "label_default_namespace" {
  provisioner "local-exec" {
    command = "echo 'Labeling default namespace for Istio sidecar injection...' && kubectl label namespace default istio-injection=enabled --overwrite"
  }

  depends_on = [
    null_resource.update_kubeconfig,
    helm_release.osdu_istio_istiod
  ]
}

# Creating the Istio Base
resource "helm_release" "osdu_istio_base" {
  name = "osdu-istio-base"
  /* Using the downloaded chart to maintain version consistency */
  # repository = "https://istio-release.storage.googleapis.com/charts"
  # chart      = "base"
  chart     = "${path.module}/charts/${var.tar_istio_base}"
  namespace = kubernetes_namespace.istio_namespace.metadata[0].name
  version   = "1.21.0"
  
  depends_on = [
    kubernetes_namespace.istio_namespace,
    aws_eks_addon.osdu_csi_addon
  ]
}

# Deploying the Istiod
resource "helm_release" "osdu_istio_istiod" {
  name = "osdu-istio-istiod"
  /* Using the downloaded chart to maintain version consistency */
  # repository = "https://istio-release.storage.googleapis.com/charts"
  # chart      = "istiod"
  chart     = "${path.module}/charts/${var.tar_istiod}"
  namespace = kubernetes_namespace.istio_namespace.metadata[0].name
  version   = "1.21.0"

  values = [
    yamlencode({
      global = {
        proxy = {
          autoInject = "enabled"
        }
      }
      pilot = {
        nodeSelector = {
          "node-role" = "osdu_istio_node"
        }
        tolerations = [
          {
            key      = "role"
            operator = "Equal"
            value    = "osdu_istio_node"
            effect   = "NoSchedule"
          }
        ]
      }
    })
  ]
  
  wait    = true
  timeout = 600
  
  depends_on = [
    helm_release.osdu_istio_base
  ]
}



# ########################################################################################################################################################################



# # ===================================
# # AWS LOAD BALANCER CONTROLLER SETUP
# # ===================================

# # Add EKS Helm repository for AWS Load Balancer Controller
# resource "helm_release" "aws_load_balancer_controller" {
#   name       = "aws-load-balancer-controller"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   version    = "1.13.3"

#   values = [
#     yamlencode({
#       clusterName = var.eks_cluster_name
      
#       serviceAccount = {
#         create = true
#         name   = "aws-load-balancer-controller"
#         annotations = {
#           "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller_role.arn
#         }
#       }

#       # Resource configuration
#       resources = {
#         limits = {
#           cpu    = "200m"
#           memory = "500Mi"
#         }
#         requests = {
#           cpu    = "100m"
#           memory = "200Mi"
#         }
#       }

#       # Node placement
#       nodeSelector = {
#         "kubernetes.io/os" = "linux"
#       }

#       # Tolerations for system workloads
#       tolerations = [
#         {
#           key      = "CriticalAddonsOnly"
#           operator = "Exists"
#         }
#       ]

#       # Additional settings
#       region = var.aws_region
#       vpcId  = data.aws_vpc.main.id
#     })
#   ]

#   # Proper dependencies
#   depends_on = [
#     aws_eks_cluster.osdu_eks_cluster_regional,
#     kubernetes_config_map_v1.aws_auth,
#     aws_iam_role.aws_load_balancer_controller_role,
#     aws_iam_role_policy_attachment.aws_load_balancer_controller_policy
#   ]

#   wait    = true
#   timeout = 600
# }

# # ===================================
# # IAM ROLE FOR AWS LOAD BALANCER CONTROLLER
# # ===================================

# # IAM Role for AWS Load Balancer Controller
# resource "aws_iam_role" "aws_load_balancer_controller_role" {
#   name = "aws-load-balancer-controller-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.osdu_eks_cluster_regional.identity[0].oidc[0].issuer, "https://", "")}"
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "${replace(aws_eks_cluster.osdu_eks_cluster_regional.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
#             "${replace(aws_eks_cluster.osdu_eks_cluster_regional.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })

#   tags = {
#     Name        = "aws-load-balancer-controller-role"
#     Environment = var.osdu_env
#   }
# }

# # IAM Policy Document for AWS Load Balancer Controller
# data "aws_iam_policy_document" "aws_load_balancer_controller_policy" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "iam:CreateServiceLinkedRole",
#       "ec2:DescribeAccountAttributes",
#       "ec2:DescribeAddresses",
#       "ec2:DescribeAvailabilityZones",
#       "ec2:DescribeInternetGateways",
#       "ec2:DescribeVpcs",
#       "ec2:DescribeSubnets",
#       "ec2:DescribeSecurityGroups",
#       "ec2:DescribeInstances",
#       "ec2:DescribeNetworkInterfaces",
#       "ec2:DescribeTags",
#       "ec2:GetCoipPoolUsage",
#       "ec2:DescribeCoipPools",
#       "elasticloadbalancing:DescribeLoadBalancers",
#       "elasticloadbalancing:DescribeLoadBalancerAttributes",
#       "elasticloadbalancing:DescribeListeners",
#       "elasticloadbalancing:DescribeListenerCertificates",
#       "elasticloadbalancing:DescribeSSLPolicies",
#       "elasticloadbalancing:DescribeRules",
#       "elasticloadbalancing:DescribeTargetGroups",
#       "elasticloadbalancing:DescribeTargetGroupAttributes",
#       "elasticloadbalancing:DescribeTargetHealth",
#       "elasticloadbalancing:DescribeTags"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "cognito-idp:DescribeUserPoolClient",
#       "acm:ListCertificates",
#       "acm:DescribeCertificate",
#       "iam:ListServerCertificates",
#       "iam:GetServerCertificate",
#       "waf-regional:GetWebACL",
#       "waf-regional:GetWebACLForResource",
#       "waf-regional:AssociateWebACL",
#       "waf-regional:DisassociateWebACL",
#       "wafv2:GetWebACL",
#       "wafv2:GetWebACLForResource",
#       "wafv2:AssociateWebACL",
#       "wafv2:DisassociateWebACL",
#       "shield:DescribeProtection",
#       "shield:GetSubscriptionState",
#       "shield:DescribeSubscription",
#       "shield:CreateProtection",
#       "shield:DeleteProtection"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "ec2:CreateSecurityGroup",
#       "ec2:CreateTags"
#     ]
#     resources = ["arn:aws:ec2:*:*:security-group/*"]
#     condition {
#       test     = "StringEquals"
#       variable = "ec2:CreateAction"
#       values   = ["CreateSecurityGroup"]
#     }
#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "ec2:CreateTags",
#       "ec2:DeleteTags"
#     ]
#     resources = ["arn:aws:ec2:*:*:security-group/*"]
#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["true"]
#     }
#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "ec2:AuthorizeSecurityGroupIngress",
#       "ec2:RevokeSecurityGroupIngress",
#       "ec2:DeleteSecurityGroup"
#     ]
#     resources = ["*"]
#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:CreateLoadBalancer",
#       "elasticloadbalancing:CreateTargetGroup"
#     ]
#     resources = ["*"]
#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:CreateListener",
#       "elasticloadbalancing:DeleteListener",
#       "elasticloadbalancing:CreateRule",
#       "elasticloadbalancing:DeleteRule"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:AddTags",
#       "elasticloadbalancing:RemoveTags"
#     ]
#     resources = [
#       "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#       "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#       "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#     ]
#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["true"]
#     }
#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:ModifyLoadBalancerAttributes",
#       "elasticloadbalancing:SetIpAddressType",
#       "elasticloadbalancing:SetSecurityGroups",
#       "elasticloadbalancing:SetSubnets",
#       "elasticloadbalancing:DeleteLoadBalancer",
#       "elasticloadbalancing:ModifyTargetGroup",
#       "elasticloadbalancing:ModifyTargetGroupAttributes",
#       "elasticloadbalancing:DeleteTargetGroup"
#     ]
#     resources = ["*"]
#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:RegisterTargets",
#       "elasticloadbalancing:DeregisterTargets"
#     ]
#     resources = ["arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "elasticloadbalancing:SetWebAcl",
#       "elasticloadbalancing:ModifyListener",
#       "elasticloadbalancing:AddListenerCertificates",
#       "elasticloadbalancing:RemoveListenerCertificates",
#       "elasticloadbalancing:ModifyRule"
#     ]
#     resources = ["*"]
#   }
# }

# # Create IAM Policy
# resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
#   name   = "AWSLoadBalancerControllerIAMPolicy"
#   policy = data.aws_iam_policy_document.aws_load_balancer_controller_policy.json

#   tags = {
#     Name        = "AWSLoadBalancerControllerIAMPolicy"
#     Environment = var.osdu_env
#   }
# }

# # Attach Policy to Role
# resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_policy" {
#   role       = aws_iam_role.aws_load_balancer_controller_role.name
#   policy_arn = aws_iam_policy.aws_load_balancer_controller_policy.arn
# }

# # ===================================
# # WAIT FOR CONTROLLER TO BE READY
# # ===================================

# # Wait for AWS Load Balancer Controller to be ready
# resource "time_sleep" "wait_for_alb_controller" {
#   depends_on = [helm_release.aws_load_balancer_controller]
  
#   create_duration = "120s"
# }

# # ===================================
# # ISTIO INGRESS GATEWAY WITH ALB
# # ===================================

# # Deploying the Istio Ingress Gateway with ALB (depends on ALB controller)
# resource "helm_release" "istio_ingressgateway" {
#   name = "istio-ingressgateway"
#   chart     = "${path.module}/charts/${var.tar_istio_gateway}"
#   namespace = kubernetes_namespace.istio_gateway_namespace.metadata[0].name
#   version   = "1.21.0"

#   values = [
#     yamlencode({
#       image = {
#         repository = "docker.io/istio/proxyv2"
#         tag        = "1.21.0"
#         pullPolicy = "IfNotPresent"
#       }

#       service = {
#         type = "LoadBalancer"
#         # Correct ALB annotations
#         annotations = {
#           "service.beta.kubernetes.io/aws-load-balancer-type" = "external"
#           "service.beta.kubernetes.io/aws-load-balancer-class" = "service.k8s.aws/alb"
#           "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
#           "service.beta.kubernetes.io/aws-load-balancer-target-type" = "ip"
#           "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "HTTP"
#           "service.beta.kubernetes.io/aws-load-balancer-listen-ports" = "[{\"HTTP\":80}, {\"HTTPS\":443}]"
#           "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol" = "HTTP"
#           "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path" = "/healthz/ready"
#           "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port" = "15021"
#         }
        
#         ports = [
#           {
#             port       = 80
#             targetPort = 8080
#             name       = "http"
#             protocol   = "TCP"
#           },
#           {
#             port       = 443
#             targetPort = 8443
#             name       = "https"
#             protocol   = "TCP"
#           }
#         ]
#       }

#       nodeSelector = {
#         "node-role" = "osdu_istio_node"
#       }

#       tolerations = [
#         {
#           key      = "role"
#           operator = "Equal"
#           value    = "osdu_istio_node"
#           effect   = "NoSchedule"
#         }
#       ]

#       # Enhanced resource configuration for ALB
#       resources = {
#         requests = {
#           cpu    = "200m"
#           memory = "256Mi"
#         }
#         limits = {
#           cpu    = "1000m"
#           memory = "512Mi"
#         }
#       }

#       # Horizontal Pod Autoscaler
#       autoscaling = {
#         enabled = true
#         minReplicas = 2
#         maxReplicas = 5
#         targetCPUUtilizationPercentage = 70
#       }
#     })
#   ]
  
#   wait    = true
#   timeout = 800
  
#   # Proper dependencies - wait for ALB controller to be ready
#   depends_on = [
#     helm_release.osdu_istio_istiod,
#     kubernetes_namespace.istio_gateway_namespace,
#     helm_release.aws_load_balancer_controller,
#     time_sleep.wait_for_alb_controller
#   ]
# }

















# # Deploying the Istio Ingress Gateway with Simple ALB
# resource "helm_release" "istio_ingressgateway" {
#   name = "istio-ingressgateway"
#   chart     = "${path.module}/charts/${var.tar_istio_gateway}"
#   namespace = kubernetes_namespace.istio_gateway_namespace.metadata[0].name
#   version   = "1.21.0"

#   values = [
#     yamlencode({
#       image = {
#         repository = "docker.io/istio/proxyv2"
#         tag        = "1.21.0"
#         pullPolicy = "IfNotPresent"
#       }

#       service = {
#         type = "LoadBalancer"
#         # Simple ALB annotations for POC
#         annotations = {
#           "service.beta.kubernetes.io/aws-load-balancer-type" = "external"
#           "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
#           "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
#           "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "http"
#         }
        
#         ports = [
#           {
#             port       = 80
#             targetPort = 8080
#             name       = "http2"
#             protocol   = "TCP"
#           },
#           {
#             port       = 443
#             targetPort = 8443
#             name       = "https"
#             protocol   = "TCP"
#           }
#         ]
#       }

#       nodeSelector = {
#         "node-role" = "osdu_istio_node"
#       }

#       tolerations = [
#         {
#           key      = "role"
#           operator = "Equal"
#           value    = "osdu_istio_node"
#           effect   = "NoSchedule"
#         }
#       ]
#     })
#   ]
  
#   wait    = true
#   timeout = 600
  
#   depends_on = [
#     helm_release.osdu_istio_istiod,
#     kubernetes_namespace.istio_gateway_namespace
#   ]
# }

# Deploying the Istio Ingress Gateway
resource "helm_release" "istio_ingressgateway" {
  name = "istio-ingressgateway"
  /* Using the downloaded chart to maintain version consistency */
  # repository = "https://istio-release.storage.googleapis.com/charts"
  # chart      = "gateway"
  chart     = "${path.module}/charts/${var.tar_istio_gateway}"
  namespace = kubernetes_namespace.istio_gateway_namespace.metadata[0].name
  version   = "1.21.0"

  values = [
    yamlencode({
      image = {
        repository = "docker.io/istio/proxyv2"
        tag        = "1.21.0"
        pullPolicy = "IfNotPresent"
      }

      service = {
        type = "LoadBalancer"
        ports = [
          {
            port       = 80
            targetPort = 8080
            name       = "http2"
          },
          {
            port       = 443
            targetPort = 8443
            name       = "https"
          }
        ]
      }

      nodeSelector = {
        "node-role" = "osdu_istio_node"
      }

      tolerations = [
        {
          key      = "role"
          operator = "Equal"
          value    = "osdu_istio_node"
          effect   = "NoSchedule"
        }
      ]
    })
  ]
  
  wait    = true
  timeout = 600
  
  depends_on = [
    helm_release.osdu_istio_istiod,
    kubernetes_namespace.istio_gateway_namespace
  ]
}

# Wait for ingress gateway to become available
resource "null_resource" "wait_for_ingressgateway" {
  depends_on = [helm_release.istio_ingressgateway]
  
  provisioner "local-exec" {
    command = "echo 'Waiting for istio-ingressgateway to become available...'"
  }
}

# Get the Istio gateway service details
data "kubernetes_service" "istio_gateway" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-gateway"
  }
  
  depends_on = [
    null_resource.wait_for_ingressgateway,
    helm_release.istio_ingressgateway
  ]
}

# Local value for gateway domain
locals {
  istio_gateway_domain = try(
    data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname,
    try(
      data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].ip,
      null
    )
  )
}

# Creating the service gateway for OSDU microservices
resource "null_resource" "osdu_service_gateway" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: service-gateway
  namespace: default
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - osdu.${local.istio_gateway_domain}
      tls:
        httpsRedirect: true
    - port:
        number: 443
        name: https
        protocol: HTTPS
      tls:
        mode: SIMPLE
        credentialName: osdu-ingress-tls
      hosts:
        - osdu.${local.istio_gateway_domain}
EOF
    EOT
  }

  depends_on = [
    helm_release.istio_ingressgateway,
    # kubernetes_secret.osdu_tls_secret,
    null_resource.update_kubeconfig,
    null_resource.wait_for_ingressgateway
  ]
}

# TLS Secret for Istio Gateway
# resource "kubernetes_secret" "osdu_tls_secret" {
#   metadata {
#     name      = "osdu-ingress-tls"
#     namespace = "istio-gateway"
#   }

#   type = "kubernetes.io/tls"

#   data = {
#     "tls.crt" = var.tls_certificate
#     "tls.key" = var.tls_private_key
#   }

#   depends_on = [
#     kubernetes_namespace.istio_gateway_namespace
#   ]
# }

# Outputs for Istio gateway
output "istio_ingress_gateway_dns" {
  description = "DNS name of the Istio ingress gateway service"
  value       = data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname
}

output "domain-name" {
  value      = local.istio_gateway_domain
  depends_on = [helm_release.istio_ingressgateway]
}

output "istio_gateway_dns" {
  value      = data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].hostname
  depends_on = [helm_release.istio_ingressgateway]
}