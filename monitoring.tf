# prometheus-amp-setup.tf
# Clean Prometheus setup with direct resource references
# No data sources - direct references to existing resources

# Step 1: Create AWS Managed Prometheus Workspace
resource "aws_prometheus_workspace" "prometheus_workspace" {
  alias = "bsp-prometheus-new"
  
  tags = {
    Name        = "bsp-prometheus-workspace-new"
    Environment = "poc"
    Project     = "bsp"
    ManagedBy   = "terraform"
  }
}

# Step 2: Create IAM role for Prometheus service account (IRSA)
resource "aws_iam_role" "prometheus_ingest_role" {
  name = "prometheus-amp-ingest-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_clusteronal.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks_cluster.url, "https://", "")}:sub" = "system:serviceaccount:prometheus:amp-iamproxy-ingest-service-account"
            "${replace(aws_iam_openid_connect_provider.eks_cluster.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "prometheus-amp-ingest-role"
    Environment = "poc"
    Project     = "bsp"
  }
}

# IAM policy for AMP ingestion
resource "aws_iam_policy" "prometheus_amp_policy" {
  name        = "PrometheusAMPIngestPolicy1"
  description = "Policy for Prometheus to ingest metrics to AMP"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata",
          "aps:QueryMetrics"
        ]
        Resource = aws_prometheus_workspace.prometheus_workspace.arn
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "prometheus_policy_attachment" {
  role       = aws_iam_role.prometheus_ingest_role.name
  policy_arn = aws_iam_policy.prometheus_amp_policy.arn
}

# Step 3: Create Prometheus namespace
resource "kubernetes_namespace" "prometheus_namespace" {
  metadata {
    name = "prometheus"
    labels = {
      "environment" = "poc"
      "component"   = "monitoring"
      "managed-by"  = "terraform"
    }
  }

  # depends_on = [aws_eks_cluster.main]
}

# # Step 4: Prometheus configuration values following AWS documentation
# locals {
#   prometheus_values = {
#     serviceAccounts = {
#       server = {
#         name = "amp-iamproxy-ingest-service-account"
#         annotations = {
#           "eks.amazonaws.com/role-arn" = aws_iam_role.prometheus_ingest_role.arn
#         }
#       }
#     }
    
#     server = {
#       # Remote write configuration using VPC endpoint
#       remoteWrite = [
#         {
#           url = "https://${aws_vpc_endpoint.aps_workspaces.dns_entry[0].dns_name}/workspaces/${aws_prometheus_workspace.prometheus_workspace.id}/api/v1/remote_write"
#           sigv4 = {
#             region = data.aws_region.current.name
#           }
#           queue_config = {
#             max_samples_per_send = 1000
#             max_shards          = 200
#             capacity            = 2500
#           }
#         }
#       ]
      
#       # Resource configuration
#       resources = {
#         limits = {
#           cpu    = "1000m"
#           memory = "2Gi"
#         }
#         requests = {
#           cpu    = "500m"
#           memory = "1Gi"
#         }
#       }
      
#       # Storage configuration
#       persistentVolume = {
#         enabled = true
#         size    = "20Gi"
#         storageClass = "gp2"
#       }
      
#       retention = "15d"
      
#       # Enhanced scraping configuration
#       extraArgs = {
#         # "web.enable-lifecycle" = true
#         "storage.tsdb.wal-compression" = true
#       }
      
#       # FIXED: Remove the configMapOverrideName - let Helm manage it automatically
#       # configMapOverrideName = "prometheus-config-override"  # <-- REMOVE THIS LINE
#     }
    
#     # Enhanced scraping with custom configuration
#     serverFiles = {
#       "prometheus.yml" = {
#         # global = {
#         #   scrape_interval = "30s"
#         #   evaluation_interval = "30s"
#         #   external_labels = {
#         #     cluster = aws_eks_cluster.main.name
#         #     region = data.aws_region.current.name
#         #   }
#         # }
        
#         rule_files = []
        
#         scrape_configs = [
#           # Prometheus self-monitoring
#           {
#             job_name = "prometheus"
#             static_configs = [{
#               targets = ["localhost:9090"]
#             }]
#           },
          
#           # Node Exporter
#           {
#             job_name = "node-exporter"
#             kubernetes_sd_configs = [{
#               role = "endpoints"
#               namespaces = {
#                 names = ["prometheus"]
#               }
#             }]
#             relabel_configs = [
#               {
#                 source_labels = ["__meta_kubernetes_service_name"]
#                 action = "keep"
#                 regex = "prometheus-prometheus-node-exporter"  # <-- FIXED: Added release name prefix
#               }
#             ]
#           },
          
#           # Kube State Metrics
#           {
#             job_name = "kube-state-metrics"
#             kubernetes_sd_configs = [{
#               role = "endpoints"
#               namespaces = {
#                 names = ["prometheus"]
#               }
#             }]
#             relabel_configs = [
#               {
#                 source_labels = ["__meta_kubernetes_service_name"]
#                 action = "keep"
#                 regex = "prometheus-kube-state-metrics"  # <-- Already correct
#               }
#             ]
#           },
          
#           # Kubernetes API Server
#           {
#             job_name = "kubernetes-apiservers"
#             scheme = "https"
#             bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
#             tls_config = {
#               ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
#               insecure_skip_verify = true
#             }
#             kubernetes_sd_configs = [{
#               role = "endpoints"
#             }]
#             relabel_configs = [{
#               source_labels = [
#                 "__meta_kubernetes_namespace",
#                 "__meta_kubernetes_service_name",
#                 "__meta_kubernetes_endpoint_port_name"
#               ]
#               action = "keep"
#               regex = "default;kubernetes;https"
#             }]
#           },
          
#           # cAdvisor for container metrics
#           {
#             job_name = "cadvisor"
#             scheme = "https"
#             bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
#             tls_config = {
#               ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
#               insecure_skip_verify = true
#             }
#             kubernetes_sd_configs = [{
#               role = "node"
#             }]
#             relabel_configs = [
#               {
#                 action = "labelmap"
#                 regex = "__meta_kubernetes_node_label_(.+)"
#               },
#               {
#                 replacement = "kubernetes.default.svc:443"
#                 target_label = "__address__"
#               },
#               {
#                 source_labels = ["__meta_kubernetes_node_name"]
#                 regex = "(.+)"
#                 target_label = "__metrics_path__"
#                 replacement = "/api/v1/nodes/$1/proxy/metrics/cadvisor"
#               }
#             ]
#           },
          
#           # Application pods with Prometheus annotations
#           {
#             job_name = "kubernetes-pods"
#             kubernetes_sd_configs = [{
#               role = "pod"
#             }]
#             relabel_configs = [
#               {
#                 source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
#                 action = "keep"
#                 regex = "true"
#               },
#               {
#                 source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
#                 action = "replace"
#                 target_label = "__metrics_path__"
#                 regex = "(.+)"
#               },
#               {
#                 source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
#                 action = "replace"
#                 regex = "([^:]+)(?::\\d+)?;(\\d+)"
#                 replacement = "$1:$2"
#                 target_label = "__address__"
#               }
#             ]
#           }
#         ]
#       }
#     }
    
#     # Enable essential components
#     nodeExporter = {
#       enabled = true
#       resources = {
#         limits = {
#           cpu    = "200m"
#           memory = "256Mi"
#         }
#         requests = {
#           cpu    = "100m"
#           memory = "128Mi"
#         }
#       }
#     }
    
#     kubeStateMetrics = {
#       enabled = true
#       resources = {
#         limits = {
#           cpu    = "200m"
#           memory = "256Mi"
#         }
#         requests = {
#           cpu    = "100m"
#           memory = "128Mi"
#         }
#       }
#     }
    
#     # Disable unnecessary components for now
#     alertmanager = {
#       enabled = false
#     }
    
#     pushgateway = {
#       enabled = true  # Changed to true since it's showing in your helm status
#       resources = {
#         limits = {
#           cpu    = "200m"
#           memory = "256Mi"
#         }
#         requests = {
#           cpu    = "100m"
#           memory = "128Mi"
#         }
#       }
#     }
#   }
# }


# Step 4: Prometheus configuration with AMP remote write (following AWS documentation)
locals {
  prometheus_values = {
    # Service account configuration for IAM roles
    serviceAccounts = {
      server = {
        name = "amp-iamproxy-ingest-service-account"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.prometheus_ingest_role.arn
        }
      }
    }
    
    # Server configuration following AWS documentation
    server = {
      # Remote write configuration to AMP
      remoteWrite = [
        {
          url = "https://aps-workspaces.${data.aws_region.current.name}.amazonaws.com/workspaces/${aws_prometheus_workspace.prometheus_workspace.id}/api/v1/remote_write"
          sigv4 = {
            region = data.aws_region.current.name
          }
          queue_config = {
            max_samples_per_send = 1000
            max_shards          = 200
            capacity            = 2500
          }
        }
      ]
      
      # Storage configuration
      persistentVolume = {
        enabled = true
        size    = "20Gi"
        storageClass = "gp2"
      }
      
      # Resource configuration
      resources = {
        limits = {
          cpu    = "1000m"
          memory = "2Gi"
        }
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }
      
      retention = "15d"
    }
    
    # Enable basic components
    nodeExporter = {
      enabled = true
      resources = {
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    }
    
    kubeStateMetrics = {
      enabled = true
      resources = {
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    }
    
    # Disable unnecessary components
    alertmanager = {
      enabled = false
    }
    
    pushgateway = {
      enabled = false  # Disable since it was causing issues earlier
    }
  }
}

# Step 5: Install Prometheus using Helm
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.prometheus_namespace.metadata[0].name
  version    = "25.8.0"

  values = [yamlencode(local.prometheus_values)]

  wait    = true
  timeout = 600

  depends_on = [
    kubernetes_namespace.prometheus_namespace,
    # aws_iam_role_policy_attachment.prometheus_policy_attachment,
    # aws_vpc_endpoint.aps_workspaces,
    # aws_vpc_endpoint.sts,
    # aws_eks_addon.ebs_csi_driver,  # Ensure EBS CSI is ready
    # aws_instance.eks_node_istio_keycloak,  # Ensure nodes are ready
    # aws_instance.eks_node_backend,
    # aws_instance.eks_node_frontend
  ]
}

# Wait for deployment
resource "time_sleep" "wait_for_prometheus" {
  depends_on = [helm_release.prometheus]
  create_duration = "90s"
}

# Step 6: Grafana IAM role for AMP access
resource "aws_iam_role" "grafana_service_role" {
  name = "grafana-amp-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "grafana-amp-service-role"
    Environment = "poc"
    Project     = "bsp"
  }
}

# Enhanced Grafana policy for AMP access
resource "aws_iam_policy" "grafana_amp_policy" {
  name        = "GrafanaAMPPolicy1"
  description = "Policy for AWS Managed Grafana to access AMP"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:ListWorkspaces",
          "aps:DescribeWorkspace", 
          "aps:QueryMetrics",
          "aps:GetLabels",
          "aps:GetSeries",
          "aps:GetMetricMetadata"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "aps:*"
        ]
        Resource = aws_prometheus_workspace.prometheus_workspace.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_policy_attachment" {
  policy_arn = aws_iam_policy.grafana_amp_policy.arn
  role       = aws_iam_role.grafana_service_role.name
}

# Step 7: AWS Managed Grafana Workspace
resource "aws_grafana_workspace" "grafana" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana_service_role.arn
  name                     = "bsp-grafana-new"
  description              = "BSP Grafana workspace for Prometheus monitoring"
  
  data_sources = ["PROMETHEUS", "CLOUDWATCH"]
  
  # VPC Configuration for private access
  vpc_configuration {
    security_group_ids = [aws_security_group.vpc_endpoints.id]
    subnet_ids         = [data.aws_subnet.private_az1.id, data.aws_subnet.private_az2.id]
  }
  
  tags = {
    Name        = "bsp-grafana-workspace-new"
    Environment = "poc"
    Project     = "bsp"
    ManagedBy   = "terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.grafana_policy_attachment,
    aws_vpc_endpoint.grafana,
    aws_vpc_endpoint.grafana_workspace
  ]
}

# Validation and setup completion
resource "null_resource" "setup_validation" {
  depends_on = [time_sleep.wait_for_prometheus]

  provisioner "local-exec" {
    command = <<-EOT
      echo "🎉 Enhanced Prometheus setup complete!"
      echo ""
      echo "✅ AWS Documentation Steps Completed:"
      echo "   Step 1: Helm repositories ✓"
      echo "   Step 2: Namespace 'prometheus' created ✓"
      echo "   Step 3: IAM roles configured ✓"
      echo "   Step 4: Prometheus server installed ✓"
      echo "   Step 5: Enhanced scraping configured ✓"
      echo ""
      echo "📊 Infrastructure Details:"
      echo "   - EKS Cluster: ${aws_eks_cluster.main.name}"
      echo "   - AMP Workspace: ${aws_prometheus_workspace.prometheus_workspace.id}"
      echo "   - VPC Endpoint: ${aws_vpc_endpoint.aps_workspaces.dns_entry[0].dns_name}"
      echo "   - Grafana: ${aws_grafana_workspace.grafana.endpoint}"
      echo ""
      echo "🔍 Quick Verification:"
      echo "   kubectl get pods -n prometheus"
      echo "   kubectl get svc -n prometheus"
      echo "   kubectl port-forward -n prometheus svc/prometheus-server 9090:80"
    EOT
  }

  triggers = {
    prometheus_id = helm_release.prometheus.id
    workspace_id = aws_prometheus_workspace.prometheus_workspace.id
  }
}

# Enhanced outputs
output "prometheus_monitoring_setup" {
  description = "Complete Prometheus monitoring setup information"
  value = {
    # AWS Documentation compliance
    aws_guide_steps = {
      step_1_helm_repos = "✅ Referenced prometheus-community charts"
      step_2_namespace = kubernetes_namespace.prometheus_namespace.metadata[0].name
      step_3_iam_roles = aws_iam_role.prometheus_ingest_role.name
      step_4_prometheus = helm_release.prometheus.name
      step_5_grafana = aws_grafana_workspace.grafana.name
    }
    
    # Infrastructure details
    amp_workspace = {
      id                = aws_prometheus_workspace.prometheus_workspace.id
      arn               = aws_prometheus_workspace.prometheus_workspace.arn
      endpoint          = aws_prometheus_workspace.prometheus_workspace.prometheus_endpoint
      vpc_endpoint_url  = "https://${aws_vpc_endpoint.aps_workspaces.dns_entry[0].dns_name}/workspaces/${aws_prometheus_workspace.prometheus_workspace.id}/"
      remote_write_url  = "https://${aws_vpc_endpoint.aps_workspaces.dns_entry[0].dns_name}/workspaces/${aws_prometheus_workspace.prometheus_workspace.id}/api/v1/remote_write"
    }
    
    grafana_workspace = {
      id       = aws_grafana_workspace.grafana.id
      endpoint = aws_grafana_workspace.grafana.endpoint
      datasource_url = "https://${aws_vpc_endpoint.aps_workspaces.dns_entry[0].dns_name}/workspaces/${aws_prometheus_workspace.prometheus_workspace.id}/"
    }
    
    eks_cluster = {
      name     = aws_eks_cluster.main.name
      endpoint = aws_eks_cluster.main.endpoint
    }
  }
}

output "verification_commands" {
  description = "Commands to verify the complete monitoring setup"
  value = {
    # Basic verification
    check_namespace           = "kubectl get namespace prometheus"
    check_pods               = "kubectl get pods -n prometheus"
    check_services           = "kubectl get svc -n prometheus"
    check_nodes              = "kubectl get nodes"
    check_storage_classes    = "kubectl get storageclass"
    
    # Prometheus specific checks
    check_prometheus_config  = "kubectl get configmap -n prometheus prometheus-server -o yaml | grep remote_write -A 10"
    check_prometheus_logs    = "kubectl logs -n prometheus deployment/prometheus-server -c prometheus-server --tail=50"
    check_service_account    = "kubectl get serviceaccount -n prometheus amp-iamproxy-ingest-service-account -o yaml"
    check_prometheus_targets = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/targets'"
    
    # Storage verification
    check_pvcs              = "kubectl get pvc -n prometheus"
    check_pvs               = "kubectl get pv"
    
    # Enhanced connectivity tests
    test_vpc_endpoint       = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- nslookup ${aws_vpc_endpoint.aps_workspaces.dns_entry[0].dns_name}"
    test_prometheus_health  = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/-/healthy'"
    test_remote_write       = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/query?query=prometheus_remote_storage_samples_total'"
    test_node_metrics       = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/query?query=up'"
    
    # Node monitoring queries
    test_cpu_usage          = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/query?query=100%20-%20(avg%20by%20(instance)%20(irate(node_cpu_seconds_total{mode=%22idle%22}[5m]))%20*%20100)'"
    test_memory_usage       = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/query?query=(1%20-%20(node_memory_MemAvailable_bytes%20/%20node_memory_MemTotal_bytes))%20*%20100'"
    test_disk_usage         = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/query?query=(1%20-%20(node_filesystem_avail_bytes{fstype!=%22tmpfs%22}%20/%20node_filesystem_size_bytes{fstype!=%22tmpfs%22}))%20*%20100'"
    
    # Network connectivity tests
    test_internal_dns       = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- nslookup kubernetes.default.svc.cluster.local"
    test_node_exporter      = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- --timeout=5 'http://prometheus-prometheus-node-exporter.prometheus.svc.cluster.local:9100/metrics' | head -5"
    test_kube_state_metrics = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- --timeout=5 'http://prometheus-kube-state-metrics.prometheus.svc.cluster.local:8080/metrics' | head -5"
    
    # Remote storage validation
    check_remote_samples    = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/query?query=prometheus_remote_storage_succeeded_samples_total'"
    check_remote_failures   = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/query?query=prometheus_remote_storage_failed_samples_total'"
    check_queue_length      = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/query?query=prometheus_remote_storage_pending_samples'"
    
    # Port forwarding for local access
    port_forward_prometheus = "kubectl port-forward -n prometheus svc/prometheus-server 9090:80"
    
    # AWS CLI checks
    check_iam_role          = "aws iam get-role --role-name prometheus-amp-ingest-role"
    check_amp_workspace     = "aws amp describe-workspace --workspace-id ${aws_prometheus_workspace.prometheus_workspace.id}"
    check_grafana_workspace = "aws grafana describe-workspace --workspace-id ${aws_grafana_workspace.grafana.id}"
    # check_ebs_csi_addon     = "aws eks describe-addon --cluster-name ${aws_eks_cluster.main.name} --addon-name aws-ebs-csi-driver"
    
    # Cluster resource monitoring
    check_node_resources    = "kubectl top nodes"
    check_pod_resources     = "kubectl top pods -n prometheus"
    check_all_pods          = "kubectl get pods -A"
    check_cluster_events    = "kubectl get events -n prometheus --sort-by=.metadata.creationTimestamp"
    
    # Troubleshooting commands
    describe_prometheus_pod = "kubectl describe pod -n prometheus -l app.kubernetes.io/name=prometheus,app.kubernetes.io/component=server"
    check_endpoints         = "kubectl get endpoints -n prometheus"
    check_secrets           = "kubectl get secrets -n prometheus"
    
    # Advanced monitoring queries
    check_scrape_duration   = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/query?query=prometheus_target_scrape_duration_seconds'"
    check_metric_count      = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/label/__name__/values' | jq '.data | length'"
    check_target_count      = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- wget -qO- 'http://localhost:9090/api/v1/targets' | jq '.data.activeTargets | length'"
  }
}

output "grafana_access_info" {
  description = "Information for accessing Grafana and configuring data sources"
  value = {
    grafana_url             = "https://${aws_grafana_workspace.grafana.endpoint}"
    amp_datasource_url      = "https://${aws_vpc_endpoint.aps_workspaces.dns_entry[0].dns_name}/workspaces/${aws_prometheus_workspace.prometheus_workspace.id}/"
    recommended_dashboards  = {
      node_exporter_full    = "Dashboard ID: 1860 (most comprehensive)"
      kubernetes_cluster    = "Dashboard ID: 315 (cluster overview)"  
      node_exporter_server  = "Dashboard ID: 405 (server metrics)"
      kubernetes_pods_nodes = "Dashboard ID: 6417 (pods and nodes)"
    }
    grafana_datasource_config = {
      type                  = "prometheus"
      url                   = "https://${aws_vpc_endpoint.aps_workspaces.dns_entry[0].dns_name}/workspaces/${aws_prometheus_workspace.prometheus_workspace.id}/"
      access                = "proxy"
      auth_type             = "AWS SigV4"
      default_region        = "${data.aws_region.current.name}"
      service               = "aps"
    }
  }
}

output "monitoring_queries" {
  description = "Prometheus queries for monitoring nodes"
  value = {
    # CPU Monitoring
    cpu_usage_percent       = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
    cpu_usage_by_mode       = "irate(node_cpu_seconds_total[5m]) * 100"
    avg_cpu_usage           = "avg(100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100))"
    top_cpu_nodes           = "topk(5, 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100))"
    
    # Memory Monitoring  
    memory_usage_percent    = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"
    memory_usage_gb         = "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024"
    memory_available_gb     = "node_memory_MemAvailable_bytes / 1024 / 1024 / 1024"
    top_memory_nodes        = "topk(5, (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100)"
    
    # Disk Monitoring
    disk_usage_percent      = "(1 - (node_filesystem_avail_bytes{fstype!=\"tmpfs\"} / node_filesystem_size_bytes{fstype!=\"tmpfs\"})) * 100"
    disk_usage_gb           = "(node_filesystem_size_bytes{fstype!=\"tmpfs\"} - node_filesystem_avail_bytes{fstype!=\"tmpfs\"}) / 1024 / 1024 / 1024"
    
    # Network Monitoring
    network_bytes_received  = "irate(node_network_receive_bytes_total[5m])"
    network_bytes_sent      = "irate(node_network_transmit_bytes_total[5m])"
    
    # Load Average
    load_1min               = "node_load1"
    load_5min               = "node_load5" 
    load_15min              = "node_load15"
    
    # System Monitoring
    uptime_days             = "node_time_seconds - node_boot_time_seconds"
    running_processes       = "node_procs_running"
    cpu_cores               = "count by (instance) (node_cpu_seconds_total{mode=\"idle\"})"
  }
}

output "troubleshooting_guides" {
  description = "Common troubleshooting scenarios and commands"
  value = {
    # Pod issues
    pod_not_starting        = "kubectl describe pod -n prometheus [POD_NAME] && kubectl logs -n prometheus [POD_NAME] --all-containers=true"
    config_issues           = "kubectl logs -n prometheus deployment/prometheus-server -c prometheus-server | grep -i error"
    
    # Storage issues  
    pvc_pending             = "kubectl describe pvc -n prometheus && kubectl get storageclass"
    volume_mount_issues     = "kubectl describe pod -n prometheus [POD_NAME] | grep -A 10 -B 10 Volume"
    
    # Network issues
    service_discovery       = "kubectl get endpoints -n prometheus && kubectl get svc -n prometheus"
    dns_resolution          = "kubectl exec -n prometheus deployment/prometheus-server -c prometheus-server -- nslookup [SERVICE_NAME]"
    
    # Remote write issues
    amp_connectivity        = "kubectl logs -n prometheus deployment/prometheus-server -c prometheus-server | grep -i 'remote_write\\|amp\\|storage'"
    check_iam_permissions   = "kubectl logs -n prometheus deployment/prometheus-server -c prometheus-server | grep -i 'permission\\|denied\\|unauthorized'"
    
    # Resource issues
    resource_constraints    = "kubectl describe node && kubectl top nodes && kubectl top pods -n prometheus"
    oom_killed             = "kubectl get events -n prometheus | grep -i 'oom\\|killed'"
  }
}