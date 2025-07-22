# # Deploying the OSDU Micro services

# resource "helm_release" "osdu_install_services" {
#   name = "osdu_install_services"
#   /* Using the downloaded chart to maintain version consistency */
#   chart     = "${path.module}/charts/${var.tar_osdu_baremetal}"
#   version   = "0.27.2"
#   namespace = "default"
#   lifecycle {
#     ignore_changes = [description]
#   }

#   # Values.yaml that will be passed to the helm chart.  
#   values = [
#     yamlencode({
#       airflow = {
#         enabled          = true
#         fullnameOverride = "airflow"
#         postgresql = {
#           enabled = false
#         }
#         externalDatabase = {
#           host     = "postgresql-db"
#           user     = "airflow_owner"
#           password = "admin123"
#           database = "airflow"
#         }
#         rbac = {
#           create = true
#         }
#         serviceaccount = {
#           create = true
#         }
#         ingress = {
#           enabled = false
#         }
#         auth = {
#           username = "admin"
#           password = "admin123"
#         }
#         dags = {
#           existingConfigmap = "dags-config"
#         }
#         worker = {
#           extraEnvVarsCM     = "airflow-config"
#           extraEnvVarsSecret = "airflow-secret"
#           podAnnotations = {
#             "sidecar.istio.io/inject" = "false"
#           }
#           automountServiceAccountToken = true
#         }
#         web = {
#           extraEnvVarsCM     = "airflow-config"
#           extraEnvVarsSecret = "airflow-secret"
#           resources = {
#             requests = {
#               cpu    = "500m"
#               memory = "1024Mi"
#             }
#             limits = {
#               cpu    = "750m"
#               memory = "1536Mi"
#             }
#           }
#         }
#         scheduler = {
#           extraEnvVarsCM     = "airflow-config"
#           extraEnvVarsSecret = "airflow-secret"
#           resources = {
#             requests = {
#               cpu    = "500m"
#               memory = "512Mi"
#             }
#             limits = {
#               cpu    = "750m"
#               memory = "1024Mi"
#             }
#           }
#         }
#         nodeSelector = {
#           "node-role" = "osdu_frontend_node"
#         }
#         tolerations = [
#           {
#             key      = "role"
#             operator = "Equal"
#             value    = "osdu_frontend_node"
#             effect   = "NoSchedule"
#           }
#         ]
#       }

#       istio = {
#         gateway = "istio-ingressgateway"
#       }

#       global = {
#         nodeSelector = {
#           "node-role" = "osdu_frontend_node"
#         }
#         dataPartitionId = var.osdu_data_partition
#         domain          = local.istio_gateway_domain
#         onPremEnabled   = true
#         useHttps        = true # making this true will require us to install the tsl certificates mentione in domain.tls
#         limitsEnabled   = true
#         logLevel        = "ERROR"
#       }

#       domain = {
#         # These certificates must be installed when we change to global.useHttps = true.
#         tls = {
#           osduCredentialName     = "osdu-ingress-tls"
#           minioCredentialName    = "minio-ingress-tls"
#           s3CredentialName       = "s3-ingress-tls"
#           keycloakCredentialName = "keycloak-ingress-tls"
#           airflowCredentialName  = "airflow-ingress-tls"
#         }
#       }

#       conf = {
#         createSecrets = true
#         nameSuffix    = ""
#       }

#       minio = {
#         mode             = "standalone"
#         enabled          = true
#         fullnameOverride = "minio"
#         statefulset = {
#           replicaCount  = 1
#           drivesPerNode = 4
#         }
#         auth = {
#           rootUser     = "minio"
#           rootPassword = "admin123"
#         }
#         persistence = {
#           enabled      = true
#           size         = "100Gi"
#           storageClass = "gp2"
#           mountPath    = "/bitnami/minio/data" # FIXME: delete it after MinIO chart update
#         }
#         extraEnvVarsCM       = "minio-config"
#         useInternalServerUrl = false
#         nodeSelector = {
#           "node-role" = "osdu_backend_node"
#         }
#         tolerations = [
#           {
#             key      = "role"
#             operator = "Equal"
#             value    = "osdu_backend_node"
#             effect   = "NoSchedule"
#           }
#         ]
#       }

#       rabbitmq = {
#         enabled          = true
#         fullnameOverride = "rabbitmq"
#         auth = {
#           username = "rabbitmq"
#           password = "admin123"
#         }
#         replicaCount = 1
#         loadDefinition = {
#           enabled        = true
#           existingSecret = "load-definition"
#         }
#         logs          = "-"
#         configuration = <<-EOT
#       ## Username and password
#       ##
#       default_user = rabbitmq
#       ## Clustering
#       cluster_name = rabbitmq
#       cluster_formation.peer_discovery_backend  = rabbit_peer_discovery_k8s
#       cluster_formation.k8s.host = kubernetes.default
#       cluster_formation.k8s.address_type = hostname
#       cluster_formation.k8s.service_name = rabbitmq-headless
#       cluster_formation.k8s.hostname_suffix = .rabbitmq-headless.default.svc.cluster.local      
#       cluster_formation.node_cleanup.interval = 10
#       cluster_formation.node_cleanup.only_log_warning = true
#       cluster_partition_handling = autoheal
#       load_definitions = /app/load_definition.json
#       # queue master locator
#       queue_master_locator = min-masters
#       # enable guest user
#       loopback_users.guest = false
#       # log level setup
#       log.connection.level = error
#       log.default.level = error
#     EOT
#         nodeSelector = {
#           "node-role" = "osdu_backend_node"
#         }
#         tolerations = [
#           {
#             key      = "role"
#             operator = "Equal"
#             value    = "osdu_backend_node"
#             effect   = "NoSchedule"
#           }
#         ]
#       }

#       postgresql = {
#         enabled          = true
#         fullnameOverride = "postgresql-db"

#         global = {
#           postgresql = {
#             auth = {
#               postgresPassword = "admin123"
#               database         = "postgres"
#             }
#           }
#         }

#         primary = {
#           persistence = {
#             enabled      = true
#             size         = "50Gi"
#             storageClass = "gp2"
#           }
#           resourcesPreset = "medium"
#         }

#         nodeSelector = {
#           "node-role" = "osdu_backend_node"
#         }

#         tolerations = [
#           {
#             key      = "role"
#             operator = "Equal"
#             value    = "osdu_backend_node"
#             effect   = "NoSchedule"
#           }
#         ]
#       }

#       elasticsearch = {
#         enabled          = true
#         fullnameOverride = "elasticsearch"

#         security = {
#           enabled         = true
#           elasticPassword = "admin123"
#           tls = {
#             autoGenerated = true
#           }
#         }

#         master = {
#           fullnameOverride = "elasticsearch"
#           masterOnly       = false
#           heapSize         = "1024m"
#           replicas         = "1"
#           persistence = {
#             size         = "10Gi"
#             storageClass = "gp2"
#           }
#         }

#         coordinating = {
#           replicas = "0"
#         }

#         data = {
#           replicas = "1"
#           persistence = {
#             size         = "100Gi"
#             storageClass = "gp2"
#           }
#         }

#         ingest = {
#           replicas = "0"
#         }

#         nodeSelector = {
#           "node-role" = "osdu_backend_node"
#         }

#         tolerations = [
#           {
#             key      = "role"
#             operator = "Equal"
#             value    = "osdu_backend_node"
#             effect   = "NoSchedule"
#           }
#         ]
#       }

#       keycloak = {
#         enabled          = true
#         fullnameOverride = "keycloak"

#         auth = {
#           adminPassword = "admin123"
#         }

#         service = {
#           type = "ClusterIP"
#         }

#         postgresql = {
#           enabled = false
#         }

#         externalDatabase = {
#           existingSecret            = "keycloak-database-secret"
#           existingSecretPasswordKey = "KEYCLOAK_DATABASE_PASSWORD"
#           existingSecretHostKey     = "KEYCLOAK_DATABASE_HOST"
#           existingSecretPortKey     = "KEYCLOAK_DATABASE_PORT"
#           existingSecretUserKey     = "KEYCLOAK_DATABASE_USER"
#           existingSecretDatabaseKey = "KEYCLOAK_DATABASE_NAME"
#         }

#         proxy = "edge" # This value will become proxy="edge" when global.useHttps = true

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

#       bootstrap = {
#         airflow = {
#           dagImages = {
#             csv_parser  = "community.opengroup.org:5555/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/gc-csv-parser:v0.27.0"
#             segy_to_zgy = "community.opengroup.org:5555/osdu/platform/data-flow/ingestion/segy-to-zgy-conversion/gc-segy-to-zgy:v0.27.2"
#             open_vds    = "community.opengroup.org:5555/osdu/platform/domain-data-mgmt-services/seismic/open-vds/openvds-ingestion:3.4.5"
#             energistics = "community.opengroup.org:5555/osdu/platform/data-flow/ingestion/energistics/witsml-parser/gc-baremetal-energistics:v0.27.0"
#           }
#           username = "admin" #needs check
#           password = "admin123"
#         }

#         postgres = {
#           external           = false
#           cloudSqlConnection = ""

#           keycloak = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "keycloak"
#             user     = "keycloak_owner"
#             password = "admin123"
#           }

#           dataset = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "dataset"
#             user     = "dataset"
#             password = "admin123"
#           }

#           entitlements = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "entitlements"
#             user     = "entitlements"
#             password = "admin123"
#             schema   = "entitlements_osdu_1"
#           }

#           file = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "file"
#             user     = "file_owner"
#             password = "admin123"
#           }

#           legal = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "legal"
#             user     = "legal_owner"
#             password = "admin123"
#           }

#           partition = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "partition"
#             user     = "partition"
#             password = "admin123"
#           }

#           register = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "register"
#             user     = "register_owner"
#             password = "admin123"
#           }

#           schema = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "schema"
#             user     = "schema"
#             password = "admin123"
#           }

#           seismic = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "seismic"
#             user     = "seismic"
#             password = "admin123"
#           }

#           storage = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "storage"
#             user     = "storage_owner"
#             password = "admin123"
#           }

#           well_delivery = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "well-delivery"
#             user     = "well_delivery_owner"
#             password = "admin123"
#           }

#           wellbore = {
#             host     = "postgresql-db"
#             port     = "5432"
#             name     = "wellbore"
#             user     = "wellbore"
#             password = "admin123"
#           }

#           workflow = {
#             host             = "postgresql-db"
#             port             = "5432"
#             name             = "workflow"
#             user             = "workflow"
#             password         = "admin123"
#             system_namespace = "osdu" #This needs check 
#           }

#           secret = {
#             postgresqlUser = "postgres"
#             postgresqlPort = "5432"
#           }
#         }

#         elastic = {
#           secret = {
#             elasticHost        = "elasticsearch"
#             elasticPort        = "9200"
#             elasticAdmin       = "elastic"
#             elasticSearchUser  = "search-service"
#             elasticIndexerUser = "indexer-service"
#           }
#           imagePullSecrets = []
#         }

#         minio = {
#           external    = false
#           console_url = ""
#           api_url     = ""

#           policy = {
#             user     = "admin" #This needs check
#             password = "admin123"
#           }

#           airflow = {
#             user     = "admin"
#             password = "admin123"
#           }

#           file = {
#             user     = "admin"
#             password = "admin123"
#           }

#           legal = {
#             user     = "admin"
#             password = "admin123"
#           }

#           storage = {
#             user     = "admin"
#             password = "admin123"
#           }

#           seismicStore = {
#             user     = "admin"
#             password = "admin123"
#             bucket   = ""
#           }

#           schema = {
#             user     = "admin"
#             password = "admin123"
#           }

#           wellbore = {
#             user     = "admin"
#             password = "admin123"
#           }

#           dag = {
#             user     = "admin"
#             password = "admin123"
#           }
#         }

#         keycloak = {
#           secret = {
#             keycloakService   = "http://keycloak"
#             keycloakRealmName = "osdu"
#           }
#         }
#       }

#       gc_baremetal_infra_bootstrap = {
#         enabled = true
#       }

#       rabbitmq_bootstrap = {
#         enabled = true
#         data = {
#           rabbitmqHost                = "rabbitmq" # matches fullnameOverride
#           rabbitmqVhost               = "/"
#           bootstrapServiceAccountName = "bootstrap-sa"
#         }
#       }

#       # This entire block is not required because these are Google Cloud Platform related params. Hence enabled=false
#       # Dont make enabled = true.
#       gc_infra_bootstrap = {
#         enabled = false
#         data = {
#           projectId          = ""
#           serviceAccountName = "infra-bootstrap"
#         }
#         airflow = {
#           bucket          = ""
#           environmentName = ""
#           location        = ""
#           dagImages = {
#             csv_parser  = "community.opengroup.org:5555/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/gc-csv-parser:v0.27.0"
#             segy_to_zgy = "community.opengroup.org:5555/osdu/platform/data-flow/ingestion/segy-to-zgy-conversion/gc-segy-to-zgy:v0.27.2"
#             open_vds    = "community.opengroup.org:5555/osdu/platform/domain-data-mgmt-services/seismic/open-vds/openvds-ingestion:3.4.5"
#             energistics = "community.opengroup.org:5555/osdu/platform/data-flow/ingestion/energistics/witsml-parser/gc-energistics:v0.27.0"
#           }
#         }
#       }

#       # Deploying of the actual OSDU microservices starts here
#       gc_entitlements_deploy = {
#         enabled = true
#         data = {
#           bootstrapServiceAccountName = "bootstrap-sa"
#           adminUserEmail              = "osdu-admin@service.local"
#           airflowComposerEmail        = "airflow@service.local"
#         }
#       }

#       gc_config_deploy = {
#         enabled = true
#       }

#       gc-crs-catalog-deploy = {
#         enabled = true
#         data = {
#           serviceAccountName = "crs-catalog"
#         }
#       }

#       gc_dataset_deploy = {
#         enabled = true
#         data = {
#           serviceAccountName = "dataset"
#         }
#         conf = {
#           postgresSecretName = "dataset-postgres-secret"
#         }
#       }

#       gc-crs-conversion-deploy = {
#         enabled = true
#       }

#       gc_partition_deploy = {
#         enabled = true
#         data = {
#           policyServiceEnabled  = "true"
#           edsEnabled            = "false"
#           autocompleteEnabled   = "false"
#           minioExternalEndpoint = "" # Leave empty for internal MinIO
#         }
#       }

#       gc_policy_deploy = {
#         enabled = true
#         data = {
#           bucketName                  = "refi-opa-policies"
#           bootstrapServiceAccountName = "bootstrap-sa"
#         }
#       }

#       gc_storage_deploy = {
#         enabled = true
#         data = {
#           bootstrapServiceAccountName = "bootstrap-sa"
#           opaEnabled                  = true
#         }
#       }

#       gc_unit_deploy = {
#         enabled = true
#       }

#       gc_register_deploy = {
#         enabled = true
#         data = {
#           serviceAccountName = "register"
#         }
#         conf = {
#           rabbitmqSecretName         = "rabbitmq-secret"
#           registerPostgresSecretName = "register-postgres-secret"
#           registerKeycloakSecretName = "register-keycloak-secret"
#         }
#       }

#       gc_notification_deploy = {
#         enabled = true
#       }

#       gc_well_delivery_deploy = {
#         enabled = true
#       }

#       gc_workflow_deploy = {
#         enabled = true
#         data = {
#           sharedTenantName            = "osdu"
#           bootstrapServiceAccountName = "bootstrap-sa"
#         }
#       }

#       gc_file_deploy = {
#         enabled = true
#         data = {
#           serviceAccountName = "file"
#         }
#       }

#       gc_schema_deploy = {
#         enabled = true
#         data = {
#           bootstrapServiceAccountName = "bootstrap-sa"
#         }
#         conf = {
#           bootstrapSecretName = "datafier-secret"
#           minioSecretName     = "schema-minio-secret"
#           postgresSecretName  = "schema-postgres-secret"
#           rabbitmqSecretName  = "rabbitmq-secret"
#         }
#       }

#       gc_search_deploy = {
#         enabled = true
#         data = {
#           servicePolicyEnabled = true
#         }
#       }

#       gc_seismic_store_sdms_deploy = {
#         enabled = true
#         data = {
#           redisDdmsHost = "redis-ddms"
#         }
#       }

#       gc_indexer_deploy = {
#         enabled = true
#         conf = {
#           elasticSecretName  = "indexer-elastic-secret"
#           keycloakSecretName = "indexer-keycloak-secret"
#           rabbitmqSecretName = "rabbitmq-secret"
#         }
#       }

#       gc_legal_deploy = {
#         enabled = false
#       }

#       core_legal_deploy = {
#         enabled = true
#         data = {
#           image                     = "community.opengroup.org:5555/osdu/platform/security-and-compliance/legal/core-plus-legal-master:latest"
#           legalStatusUpdateImage    = "community.opengroup.org:5555/osdu/platform/security-and-compliance/legal/core-plus-legal-master:latest"
#           imagePullPolicy           = "IfNotPresent"
#           cronJobServiceAccountName = "bootstrap-sa"
#         }
#       }

#       gc_wellbore_deploy = {
#         enabled = true
#       }

#       gc_wellbore_worker_deploy = {
#         enabled = true
#       }

#       gc_secret_deploy = {
#         enabled = true
#       }

#       gc_eds_dms_deploy = {
#         enabled = true
#       }

#       gc_oetp_client_deploy = {
#         enabled = false
#       }

#       gc_oetp_server_deploy = {
#         enabled = false
#       }

#       dfaas_tests = {
#         enabled = false
#       }
#     })
#   ]
#   timeout           = 1200
#   wait              = true
#   dependency_update = true
#   depends_on = [
#     aws_eks_addon.osdu_csi_addon,
#     null_resource.update_kubeconfig,
#     null_resource.label_default_namespace,
#     helm_release.istio_ingressgateway,
#     kubernetes_secret.osdu_tls_secret,
#     kubernetes_secret.minio_tls_secret,
#     kubernetes_secret.s3_tls_secret,
#     kubernetes_secret.airflow_tls_secret,
#     kubernetes_secret.keycloak_tls_secret
#   ]
# }
