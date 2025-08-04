# # # This script generates the required certificates for https communication

# # # Used for https connection
# # resource "tls_private_key" "osdu_tls_key" {
# #   algorithm = "RSA"
# #   rsa_bits  = 2048
# # }

# # # Creating a self signed certificate
# # resource "tls_self_signed_cert" "osdu_tls_cert" {

# #   private_key_pem = tls_private_key.osdu_tls_key.private_key_pem

# #   subject {
# #     common_name  = "osdu.${local.istio_gateway_domain}"
# #     organization = "OSDU"
# #   }

# #   validity_period_hours = 8760 # 1 year
# #   early_renewal_hours   = 720
# #   is_ca_certificate     = false

# #   allowed_uses = [
# #     "key_encipherment",
# #     "digital_signature",
# #     "server_auth",
# #   ]

# #   dns_names = ["osdu.${local.istio_gateway_domain}"]
# # }

# # # Creating the TLS secret 
# # resource "kubernetes_secret" "osdu_tls_secret" {
# #   metadata {
# #     name      = "osdu-ingress-tls"
# #     namespace = "istio-system"
# #   }

# #   data = {
# #     "tls.crt" = tls_self_signed_cert.osdu_tls_cert.cert_pem
# #     "tls.key" = tls_private_key.osdu_tls_key.private_key_pem
# #   }

# #   type = "kubernetes.io/tls"

# #   depends_on = [null_resource.update_kubeconfig]
# # }

# # # Creating for minio
# # resource "tls_private_key" "minio_tls_key" {
# #   algorithm = "RSA"
# #   rsa_bits  = 2048
# # }

# # resource "tls_self_signed_cert" "minio_tls_cert" {

# #   private_key_pem = tls_private_key.minio_tls_key.private_key_pem

# #   subject {
# #     common_name  = "minio.${local.istio_gateway_domain}"
# #     organization = "OSDU"
# #   }

# #   validity_period_hours = 8760 # 1 year
# #   early_renewal_hours   = 720
# #   is_ca_certificate     = false

# #   allowed_uses = [
# #     "key_encipherment",
# #     "digital_signature",
# #     "server_auth",
# #   ]

# #   dns_names = ["minio.${local.istio_gateway_domain}"]
# # }

# # resource "kubernetes_secret" "minio_tls_secret" {
# #   metadata {
# #     name      = "minio-ingress-tls"
# #     namespace = "istio-system"
# #   }

# #   data = {
# #     "tls.crt" = tls_self_signed_cert.minio_tls_cert.cert_pem
# #     "tls.key" = tls_private_key.minio_tls_key.private_key_pem
# #   }

# #   type = "kubernetes.io/tls"

# #   depends_on = [null_resource.update_kubeconfig]
# # }


# # # Creating for S3
# # resource "tls_private_key" "s3_tls_key" {
# #   algorithm = "RSA"
# #   rsa_bits  = 2048
# # }

# # resource "tls_self_signed_cert" "s3_tls_cert" {

# #   private_key_pem = tls_private_key.s3_tls_key.private_key_pem

# #   subject {
# #     common_name  = "s3.${local.istio_gateway_domain}"
# #     organization = "OSDU"
# #   }


# #   validity_period_hours = 8760
# #   early_renewal_hours   = 720
# #   is_ca_certificate     = false

# #   allowed_uses = [
# #     "key_encipherment",
# #     "digital_signature",
# #     "server_auth",
# #   ]
# #   dns_names = ["s3.${local.istio_gateway_domain}"]
# # }

# # resource "kubernetes_secret" "s3_tls_secret" {
# #   metadata {
# #     name      = "s3-ingress-tls"
# #     namespace = "istio-system"
# #   }

# #   data = {
# #     "tls.crt" = tls_self_signed_cert.s3_tls_cert.cert_pem
# #     "tls.key" = tls_private_key.s3_tls_key.private_key_pem
# #   }

# #   type = "kubernetes.io/tls"

# #   depends_on = [null_resource.update_kubeconfig]
# # }


# # # Creating for keycloak
# # resource "tls_private_key" "keycloak_tls_key" {
# #   algorithm = "RSA"
# #   rsa_bits  = 2048
# # }

# # resource "tls_self_signed_cert" "keycloak_tls_cert" {

# #   private_key_pem = tls_private_key.keycloak_tls_key.private_key_pem

# #   subject {
# #     common_name  = "keycloak.${local.istio_gateway_domain}"
# #     organization = "OSDU"
# #   }


# #   validity_period_hours = 8760
# #   early_renewal_hours   = 720
# #   is_ca_certificate     = false

# #   allowed_uses = [
# #     "key_encipherment",
# #     "digital_signature",
# #     "server_auth",
# #   ]
# #   dns_names = ["keycloak.${local.istio_gateway_domain}"]
# # }


# # resource "kubernetes_secret" "keycloak_tls_secret" {
# #   metadata {
# #     name      = "keycloak-ingress-tls"
# #     namespace = "istio-system"
# #   }

# #   data = {
# #     "tls.crt" = tls_self_signed_cert.keycloak_tls_cert.cert_pem
# #     "tls.key" = tls_private_key.keycloak_tls_key.private_key_pem
# #   }

# #   type = "kubernetes.io/tls"

# #   depends_on = [null_resource.update_kubeconfig]
# # }


# # # Creating for airflow
# # resource "tls_private_key" "airflow_tls_key" {
# #   algorithm = "RSA"
# #   rsa_bits  = 2048
# # }

# # resource "tls_self_signed_cert" "airflow_tls_cert" {
# #   private_key_pem = tls_private_key.airflow_tls_key.private_key_pem

# #   subject {
# #     common_name  = "airflow.${local.istio_gateway_domain}"
# #     organization = "OSDU"
# #   }


# #   validity_period_hours = 8760
# #   early_renewal_hours   = 720
# #   is_ca_certificate     = false

# #   allowed_uses = [
# #     "key_encipherment",
# #     "digital_signature",
# #     "server_auth",
# #   ]
# #   dns_names = ["airflow.${local.istio_gateway_domain}"]
# # }

# # resource "kubernetes_secret" "airflow_tls_secret" {
# #   metadata {
# #     name      = "airflow-ingress-tls"
# #     namespace = "istio-system"
# #   }

# #   data = {
# #     "tls.crt" = tls_self_signed_cert.airflow_tls_cert.cert_pem
# #     "tls.key" = tls_private_key.airflow_tls_key.private_key_pem
# #   }

# #   type = "kubernetes.io/tls"

# #   depends_on = [null_resource.update_kubeconfig]
# # }






# # This script generates the required certificates for https communication

# # Used for https connection
# resource "tls_private_key" "osdu_tls_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# # Creating a self signed certificate
# resource "tls_self_signed_cert" "osdu_tls_cert" {
#   private_key_pem = tls_private_key.osdu_tls_key.private_key_pem

#   subject {
#     common_name  = "osdu.${local.istio_gateway_domain}"
#     organization = "OSDU"
#   }

#   validity_period_hours = 8760 # 1 year
#   early_renewal_hours   = 720
#   is_ca_certificate     = false

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]

#   dns_names = ["osdu.${local.istio_gateway_domain}"]
# }

# # Creating the TLS secret in BOTH namespaces
# resource "kubernetes_secret" "osdu_tls_secret_istio_system" {
#   metadata {
#     name      = "osdu-ingress-tls"
#     namespace = "istio-system"
#   }

#   data = {
#     "tls.crt" = tls_self_signed_cert.osdu_tls_cert.cert_pem
#     "tls.key" = tls_private_key.osdu_tls_key.private_key_pem
#   }

#   type = "kubernetes.io/tls"

#   depends_on = [kubernetes_namespace.istio_namespace]
# }

# resource "kubernetes_secret" "osdu_tls_secret" {
#   metadata {
#     name      = "osdu-ingress-tls"
#     namespace = "istio-gateway"
#   }

#   data = {
#     "tls.crt" = tls_self_signed_cert.osdu_tls_cert.cert_pem
#     "tls.key" = tls_private_key.osdu_tls_key.private_key_pem
#   }

#   type = "kubernetes.io/tls"

#   depends_on = [kubernetes_namespace.istio_gateway_namespace]
# }

# # Creating for minio
# resource "tls_private_key" "minio_tls_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# resource "tls_self_signed_cert" "minio_tls_cert" {
#   private_key_pem = tls_private_key.minio_tls_key.private_key_pem

#   subject {
#     common_name  = "minio.${local.istio_gateway_domain}"
#     organization = "OSDU"
#   }

#   validity_period_hours = 8760 # 1 year
#   early_renewal_hours   = 720
#   is_ca_certificate     = false

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]

#   dns_names = ["minio.${local.istio_gateway_domain}"]
# }

# resource "kubernetes_secret" "minio_tls_secret_istio_system" {
#   metadata {
#     name      = "minio-ingress-tls"
#     namespace = "istio-system"
#   }

#   data = {
#     "tls.crt" = tls_self_signed_cert.minio_tls_cert.cert_pem
#     "tls.key" = tls_private_key.minio_tls_key.private_key_pem
#   }

#   type = "kubernetes.io/tls"

#   depends_on = [kubernetes_namespace.istio_namespace]
# }

# resource "kubernetes_secret" "minio_tls_secret" {
#   metadata {
#     name      = "minio-ingress-tls"
#     namespace = "istio-gateway"
#   }

#   data = {
#     "tls.crt" = tls_self_signed_cert.minio_tls_cert.cert_pem
#     "tls.key" = tls_private_key.minio_tls_key.private_key_pem
#   }

#   type = "kubernetes.io/tls"

#   depends_on = [kubernetes_namespace.istio_gateway_namespace]
# }

# # Creating for S3
# resource "tls_private_key" "s3_tls_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# resource "tls_self_signed_cert" "s3_tls_cert" {
#   private_key_pem = tls_private_key.s3_tls_key.private_key_pem

#   subject {
#     common_name  = "s3.${local.istio_gateway_domain}"
#     organization = "OSDU"
#   }

#   validity_period_hours = 8760
#   early_renewal_hours   = 720
#   is_ca_certificate     = false

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]
#   dns_names = ["s3.${local.istio_gateway_domain}"]
# }

# resource "kubernetes_secret" "s3_tls_secret_istio_system" {
#   metadata {
#     name      = "s3-ingress-tls"
#     namespace = "istio-system"
#   }

#   data = {
#     "tls.crt" = tls_self_signed_cert.s3_tls_cert.cert_pem
#     "tls.key" = tls_private_key.s3_tls_key.private_key_pem
#   }

#   type = "kubernetes.io/tls"

#   depends_on = [kubernetes_namespace.istio_namespace]
# }

# resource "kubernetes_secret" "s3_tls_secret" {
#   metadata {
#     name      = "s3-ingress-tls"
#     namespace = "istio-gateway"
#   }

#   data = {
#     "tls.crt" = tls_self_signed_cert.s3_tls_cert.cert_pem
#     "tls.key" = tls_private_key.s3_tls_key.private_key_pem
#   }

#   type = "kubernetes.io/tls"

#   depends_on = [kubernetes_namespace.istio_gateway_namespace]
# }

# # Creating for keycloak
# resource "tls_private_key" "keycloak_tls_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# resource "tls_self_signed_cert" "keycloak_tls_cert" {
#   private_key_pem = tls_private_key.keycloak_tls_key.private_key_pem

#   subject {
#     common_name  = "keycloak.${local.istio_gateway_domain}"
#     organization = "OSDU"
#   }

#   validity_period_hours = 8760
#   early_renewal_hours   = 720
#   is_ca_certificate     = false

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]
#   dns_names = ["keycloak.${local.istio_gateway_domain}"]
# }

# resource "kubernetes_secret" "keycloak_tls_secret_istio_system" {
#   metadata {
#     name      = "keycloak-ingress-tls"
#     namespace = "istio-system"
#   }

#   data = {
#     "tls.crt" = tls_self_signed_cert.keycloak_tls_cert.cert_pem
#     "tls.key" = tls_private_key.keycloak_tls_key.private_key_pem
#   }

#   type = "kubernetes.io/tls"

#   depends_on = [kubernetes_namespace.istio_namespace]
# }

# resource "kubernetes_secret" "keycloak_tls_secret" {
#   metadata {
#     name      = "keycloak-ingress-tls"
#     namespace = "istio-gateway"
#   }

#   data = {
#     "tls.crt" = tls_self_signed_cert.keycloak_tls_cert.cert_pem
#     "tls.key" = tls_private_key.keycloak_tls_key.private_key_pem
#   }

#   type = "kubernetes.io/tls"

#   depends_on = [kubernetes_namespace.istio_gateway_namespace]
# }

# # Creating for airflow
# resource "tls_private_key" "airflow_tls_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# resource "tls_self_signed_cert" "airflow_tls_cert" {
#   private_key_pem = tls_private_key.airflow_tls_key.private_key_pem

#   subject {
#     common_name  = "airflow.${local.istio_gateway_domain}"
#     organization = "OSDU"
#   }

#   validity_period_hours = 8760
#   early_renewal_hours   = 720
#   is_ca_certificate     = false

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]
#   dns_names = ["airflow.${local.istio_gateway_domain}"]
# }

# resource "kubernetes_secret" "airflow_tls_secret_istio_system" {
#   metadata {
#     name      = "airflow-ingress-tls"
#     namespace = "istio-system"
#   }

#   data = {
#     "tls.crt" = tls_self_signed_cert.airflow_tls_cert.cert_pem
#     "tls.key" = tls_private_key.airflow_tls_key.private_key_pem
#   }

#   type = "kubernetes.io/tls"

#   depends_on = [kubernetes_namespace.istio_namespace]
# }

# resource "kubernetes_secret" "airflow_tls_secret" {
#   metadata {
#     name      = "airflow-ingress-tls"
#     namespace = "istio-gateway"
#   }

#   data = {
#     "tls.crt" = tls_self_signed_cert.airflow_tls_cert.cert_pem
#     "tls.key" = tls_private_key.airflow_tls_key.private_key_pem
#   }

#   type = "kubernetes.io/tls"

#   depends_on = [kubernetes_namespace.istio_gateway_namespace]
# }
