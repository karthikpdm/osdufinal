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
  name = "osdu_istio_base"
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
  name = "osdu_istio_istiod"
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
    kubernetes_secret.osdu_tls_secret,
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