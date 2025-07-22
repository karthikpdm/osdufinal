# OSDU Platform Endpoints and Troubleshooting Outputs

# Get Load Balancer DNS Name
data "kubernetes_service" "istio_gateway_details" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-gateway"
  }
  depends_on = [helm_release.istio_ingressgateway]
}

# Main OSDU Platform Endpoints
output "osdu_platform_endpoints" {
  description = "All OSDU platform service endpoints"
  value = {
    # Main Platform URL
    platform_base_url = "https://osdu.${local.istio_gateway_domain}"
    
    # Core Data Services
    storage_service       = "https://osdu.${local.istio_gateway_domain}/api/storage/v2"
    dataset_service       = "https://osdu.${local.istio_gateway_domain}/api/dataset/v1" 
    file_service         = "https://osdu.${local.istio_gateway_domain}/api/file/v2"
    schema_service       = "https://osdu.${local.istio_gateway_domain}/api/schema-service/v1"
    search_service       = "https://osdu.${local.istio_gateway_domain}/api/search/v2"
    indexer_service      = "https://osdu.${local.istio_gateway_domain}/api/indexer/v2"
    
    # Security Services  
    entitlements_service = "https://osdu.${local.istio_gateway_domain}/api/entitlements/v2"
    legal_service        = "https://osdu.${local.istio_gateway_domain}/api/legal/v1"
    partition_service    = "https://osdu.${local.istio_gateway_domain}/api/partition/v1"
    
    # Domain Services
    wellbore_service     = "https://osdu.${local.istio_gateway_domain}/api/wellbore/v3"
    well_delivery_service = "https://osdu.${local.istio_gateway_domain}/api/well-delivery/v2"
    seismic_service      = "https://osdu.${local.istio_gateway_domain}/api/seismic-store/v3"
    unit_service         = "https://osdu.${local.istio_gateway_domain}/api/unit/v3"
    workflow_service     = "https://osdu.${local.istio_gateway_domain}/api/workflow/v1"
    
    # Specialized Services
    crs_catalog_service  = "https://osdu.${local.istio_gateway_domain}/api/crs/catalog/v2"
    crs_conversion_service = "https://osdu.${local.istio_gateway_domain}/api/crs/conversion/v2"
    register_service     = "https://osdu.${local.istio_gateway_domain}/api/register/v1"
    notification_service = "https://osdu.${local.istio_gateway_domain}/api/notification/v1"
    secret_service       = "https://osdu.${local.istio_gateway_domain}/api/secret/v1"
    
    # Infrastructure Services
    keycloak_admin       = "https://keycloak.${local.istio_gateway_domain}"
    keycloak_auth        = "https://keycloak.${local.istio_gateway_domain}/auth"
    minio_console        = "https://minio.${local.istio_gateway_domain}"
    minio_api            = "https://s3.${local.istio_gateway_domain}"
    airflow_web          = "https://airflow.${local.istio_gateway_domain}"
  }
}

# Service Health Check Endpoints
output "health_check_endpoints" {
  description = "Health check endpoints for all services"
  value = {
    # Core Services Health
    storage_health       = "https://osdu.${local.istio_gateway_domain}/api/storage/v2/_ah/warmup"
    dataset_health       = "https://osdu.${local.istio_gateway_domain}/api/dataset/v1/_ah/warmup"
    file_health          = "https://osdu.${local.istio_gateway_domain}/api/file/v2/_ah/warmup"
    schema_health        = "https://osdu.${local.istio_gateway_domain}/api/schema-service/v1/_ah/warmup"
    search_health        = "https://osdu.${local.istio_gateway_domain}/api/search/v2/_ah/warmup"
    indexer_health       = "https://osdu.${local.istio_gateway_domain}/api/indexer/v2/_ah/warmup"
    entitlements_health  = "https://osdu.${local.istio_gateway_domain}/api/entitlements/v2/_ah/warmup"
    legal_health         = "https://osdu.${local.istio_gateway_domain}/api/legal/v1/_ah/warmup"
    partition_health     = "https://osdu.${local.istio_gateway_domain}/api/partition/v1/_ah/warmup"
    wellbore_health      = "https://osdu.${local.istio_gateway_domain}/api/wellbore/v3/_ah/warmup"
    workflow_health      = "https://osdu.${local.istio_gateway_domain}/api/workflow/v1/_ah/warmup"
  }
}

# Infrastructure Details
output "infrastructure_details" {
  description = "Infrastructure service details and internal URLs"
  value = {
    # Load Balancer Details
    load_balancer_dns    = try(data.kubernetes_service.istio_gateway_details.status[0].load_balancer[0].ingress[0].hostname, "pending")
    load_balancer_ip     = try(data.kubernetes_service.istio_gateway_details.status[0].load_balancer[0].ingress[0].ip, "pending")
    
    # EKS Cluster Details
    eks_cluster_name     = aws_eks_cluster.osdu_eks_cluster_regional.name
    eks_cluster_endpoint = aws_eks_cluster.osdu_eks_cluster_regional.endpoint
    eks_cluster_version  = aws_eks_cluster.osdu_eks_cluster_regional.version
    
    # Internal Service URLs (for debugging)
    internal_postgresql  = "postgresql-db.default.svc.cluster.local:5432"
    internal_elasticsearch = "elasticsearch.default.svc.cluster.local:9200"
    internal_minio      = "minio.default.svc.cluster.local:9000"
    internal_rabbitmq   = "rabbitmq.default.svc.cluster.local:5672"
    internal_keycloak   = "keycloak.default.svc.cluster.local:8080"
    internal_redis      = "osdu-install-services-redis-master.default.svc.cluster.local:6379"
  }
}

# Troubleshooting Commands
output "troubleshooting_guide" {
  description = "Comprehensive troubleshooting commands for OSDU platform"
  value = {
    # Cluster Health
    cluster_status = "kubectl cluster-info && kubectl get nodes -o wide"
    cluster_events = "kubectl get events --sort-by='.lastTimestamp' -A | tail -20"
    
    # Pod Issues
    all_pods_status = "kubectl get pods -A -o wide"
    failing_pods = "kubectl get pods -A --field-selector=status.phase!=Running"
    pod_describe = "kubectl describe pod -n [NAMESPACE] [POD_NAME]"
    pod_logs = "kubectl logs -n [NAMESPACE] [POD_NAME] --tail=100 -f"
    pod_events = "kubectl get events -n [NAMESPACE] --field-selector involvedObject.name=[POD_NAME]"
    
    # Service Discovery
    all_services = "kubectl get svc -A"
    endpoints_check = "kubectl get endpoints -A"
    istio_gateway_svc = "kubectl get svc -n istio-gateway istio-ingressgateway -o yaml"
    
    # Istio Specific
    istio_proxy_status = "kubectl get pods -n istio-system && kubectl get pods -n istio-gateway"
    istio_gateway_logs = "kubectl logs -n istio-gateway deployment/istio-ingressgateway -f"
    istio_config_dump = "kubectl exec -n istio-gateway deployment/istio-ingressgateway -- pilot-agent request GET config_dump"
    
    # Storage Issues
    persistent_volumes = "kubectl get pv,pvc -A"
    storage_classes = "kubectl get storageclass"
    volume_issues = "kubectl describe pvc -A | grep -A 10 -B 10 'Events\\|Error\\|Warning'"
    
    # Database Connectivity
    postgres_connection = "kubectl exec -n default postgresql-db-0 -- psql -U postgres -c '\\l'"
    elasticsearch_health = "kubectl exec -n default elasticsearch-0 -- curl -u elastic:admin123 -k https://localhost:9200/_cluster/health?pretty"
    minio_health = "kubectl exec -n default deployment/minio -- mc admin info local || echo 'MinIO not accessible'"
    rabbitmq_status = "kubectl exec -n default rabbitmq-0 -- rabbitmqctl status"
    
    # Authentication Issues
    keycloak_logs = "kubectl logs -n default keycloak-0 -c keycloak --tail=50"
    keycloak_health = "kubectl exec -n default keycloak-0 -- curl -f http://localhost:8080/auth/realms/master || echo 'Keycloak not ready'"
    
    # Network Connectivity
    dns_resolution = "kubectl run -i --tty --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default.svc.cluster.local"
    service_mesh_check = "kubectl exec -n [NAMESPACE] [POD_NAME] -- curl -I http://istio-ingressgateway.istio-gateway.svc.cluster.local"
    
    # Resource Usage
    node_resources = "kubectl top nodes"
    pod_resources = "kubectl top pods -A --sort-by=cpu"
    resource_quotas = "kubectl describe quota -A"
    
    # Certificate Issues
    tls_secrets = "kubectl get secrets -A | grep tls"
    certificate_check = "kubectl get secret osdu-ingress-tls -n istio-system -o jsonpath='{.data.tls\\.crt}' | base64 -d | openssl x509 -text -noout"
    
    # OSDU Specific Debugging
    bootstrap_status = "kubectl get pods | grep bootstrap"
    osdu_config_maps = "kubectl get configmaps | grep -E '(osdu|airflow|minio)'"
    osdu_secrets = "kubectl get secrets | grep -E '(osdu|postgres|elastic|minio|rabbitmq|keycloak)'"
    
    # Load Balancer Issues
    lb_status = "kubectl describe svc istio-ingressgateway -n istio-gateway"
    ingress_controller = "kubectl get pods -n istio-gateway -l app=istio-ingressgateway -o wide"
    
    # Application Logs (Key Services)
    storage_logs = "kubectl logs deployment/storage -c storage --tail=100"
    entitlements_logs = "kubectl logs deployment/entitlements -c entitlements --tail=100"
    indexer_logs = "kubectl logs deployment/indexer -c indexer --tail=100"
    search_logs = "kubectl logs deployment/search -c search --tail=100"
    airflow_logs = "kubectl logs deployment/airflow-web -c airflow-web --tail=100"
  }
}

# Quick Validation Commands
output "quick_validation_commands" {
  description = "Quick commands to validate OSDU platform functionality"
  value = {
    # External Access Test
    external_health_check = "curl -k -I https://osdu.${local.istio_gateway_domain}"
    
    # Service Availability
    storage_api_test = "curl -k -H 'Accept: application/json' https://osdu.${local.istio_gateway_domain}/api/storage/v2/info"
    entitlements_test = "curl -k -H 'Accept: application/json' https://osdu.${local.istio_gateway_domain}/api/entitlements/v2/info"
    search_test = "curl -k -H 'Accept: application/json' https://osdu.${local.istio_gateway_domain}/api/search/v2/info"
    
    # Authentication Test
    keycloak_test = "curl -k -I https://keycloak.${local.istio_gateway_domain}/auth/realms/osdu"
    
    # Infrastructure Test
    minio_test = "curl -k -I https://minio.${local.istio_gateway_domain}"
    airflow_test = "curl -k -I https://airflow.${local.istio_gateway_domain}"
  }
}

# Platform Information
output "platform_information" {
  description = "Key platform information and credentials"
  value = {
    # Default Credentials (Change in production!)
    keycloak_admin = {
      username = "admin"
      password = "admin123"
      url = "https://keycloak.${local.istio_gateway_domain}/auth/admin/"
    }
    
    airflow_admin = {
      username = "admin" 
      password = "admin123"
      url = "https://airflow.${local.istio_gateway_domain}"
    }
    
    minio_admin = {
      username = "minio"
      password = "admin123"
      url = "https://minio.${local.istio_gateway_domain}"
    }
    
    # Database Info
    postgresql_info = {
      host = "postgresql-db.default.svc.cluster.local"
      port = 5432
      admin_user = "postgres"
      admin_password = "admin123"
    }
    
    elasticsearch_info = {
      host = "elasticsearch.default.svc.cluster.local"
      port = 9200
      admin_user = "elastic"
      admin_password = "admin123"
    }
    
    # OSDU Configuration
    osdu_partition = var.osdu_data_partition
    osdu_domain = local.istio_gateway_domain
  }
}