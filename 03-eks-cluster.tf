# Check if wheter this role is present using command 
# aws iam get-role --role-name AWSServiceRoleForAmazonEKS --region ap-southeast-1
# If not present then you can create it using the below command
# aws iam create-service-linked-role --aws-service-name eks.amazonaws.com
# Command to run kubeconfig
# aws eks update-kubeconfig --region ap-southeast-1 --name osdu_eks_cluster

# Also we need the default endpoints for EKS local cluster
# Endpoint	                              Endpoint type
# com.amazonaws.region-code.ssm             Interface
# com.amazonaws.region-code.ssmmessages     Interface
# com.amazonaws.region-code.ec2messages     Interface
# com.amazonaws.region-code.ec2             Interface
# com.amazonaws.region-code.secretsmanager  Interface
# com.amazonaws.region-code.logs            Interface
# com.amazonaws.region-code.sts             Interface
# com.amazonaws.region-code.ecr.api         Interface
# com.amazonaws.region-code.ecr.dkr         Interface
# com.amazonaws.region-code.s3              Gateway


###############################################################################################################################################################################

#                                                                 eks for outpost


################################################################################################################################################################################

# # EKS Cluster role
# resource "aws_iam_role" "osdu_eks_cluster_role" {
#   name = "osdu_eks_cluster_role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = [
#             "eks.amazonaws.com",
#             "ec2.amazonaws.com"
#           ]
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
#   tags = {
#     Name = "osdu_eks_cluster_role"
#   }
# }

# resource "aws_iam_role_policy_attachment" "osdu_eks_cluster_policy_attach" {
#   role       = aws_iam_role.osdu_eks_cluster_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# resource "aws_iam_role_policy_attachment" "osdu_eks_service_policy_attach" {
#   role       = aws_iam_role.osdu_eks_cluster_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
# }

# resource "aws_iam_role_policy_attachment" "osdu_eks_local_outpost_policy_attach" {
#   role       = aws_iam_role.osdu_eks_cluster_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLocalOutpostClusterPolicy"
# }

# # Creating the EKS Cluster
# resource "aws_eks_cluster" "osdu_eks_cluster" {
#   name     = var.eks_cluster_name
#   version  = var.eks_version
#   role_arn = aws_iam_role.osdu_eks_cluster_role.arn

#   vpc_config {
#     endpoint_private_access = true
#     endpoint_public_access  = false

#     subnet_ids = [
#       var.osdu_subnet_id
#     ]
#   }

#   enabled_cluster_log_types = [
#     "api",
#     "audit",
#     "authenticator"
#   ]

#   outpost_config {
#     control_plane_instance_type = var.instance_type_controller
#     outpost_arns                = [var.osdu_outpost_arn]
#   }

#   tags = {
#     Name        = var.eks_cluster_name
#     Environment = var.osdu_env
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.osdu_eks_cluster_policy_attach,
#     aws_iam_role_policy_attachment.osdu_eks_service_policy_attach,
#     aws_iam_role_policy_attachment.osdu_eks_local_outpost_policy_attach
#   ]
# }

# output "osdu_eks_cluster_arn" {
#   value      = aws_eks_cluster.osdu_eks_cluster.arn
#   depends_on = [aws_eks_cluster.osdu_eks_cluster]
# }


###############################################################################################################################################################################

#                                                                 eks for region


################################################################################################################################################################################


# EKS Cluster IAM role for regional deployment
resource "aws_iam_role" "osdu_eks_cluster_role" {
  name = "osdu_eks_cluster_role_regional"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "eks.amazonaws.com"
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "osdu_eks_cluster_role_regional"
    Environment = var.osdu_env
  }
}

# Attach required policies for regional EKS cluster
resource "aws_iam_role_policy_attachment" "osdu_eks_cluster_policy_attach_regional" {
  role       = aws_iam_role.osdu_eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# CloudWatch Log Group for EKS cluster logging
resource "aws_cloudwatch_log_group" "osdu_eks_cluster_regional" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = "7"

  tags = {
    Name        = "${var.eks_cluster_name}-logs"
    Environment = var.osdu_env
  }
}

# Regional EKS Cluster (references existing data sources and security groups)
resource "aws_eks_cluster" "osdu_eks_cluster_regional" {
  name     = var.eks_cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.osdu_eks_cluster_role.arn

  vpc_config {
    # Reference existing subnets from datasource.tf
    subnet_ids              = [data.aws_subnet.private_az1.id, data.aws_subnet.private_az2.id]
    # Reference existing security group from datasource.tf
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true  # API server NOT accessible from internet
    public_access_cidrs     = ["0.0.0.0/0"]     # Empty since public access is disabled
    # endpoint_public_access  = var.enable_public_access # Set to false for private clusters
    # public_access_cidrs     = var.enable_public_access ? var.public_access_cidrs : []
  }

  # Enable comprehensive EKS Cluster logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Modern access configuration
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Name        = var.eks_cluster_name
    Environment = var.osdu_env
    Project     = "OSDU"
  }

  depends_on = [
    aws_iam_role_policy_attachment.osdu_eks_cluster_policy_attach_regional,
    aws_cloudwatch_log_group.osdu_eks_cluster_regional,
  ]

  lifecycle {
    ignore_changes = [
      vpc_config[0].public_access_cidrs,
      vpc_config[0].endpoint_private_access,
      vpc_config[0].endpoint_public_access,
    ]
  }
}


# Static thumbprint approach (no internet needed)
# resource "aws_iam_openid_connect_provider" "eks_cluster" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]  # AWS standard thumbprint
#   url             = aws_eks_cluster.osdu_eks_cluster_regional.identity[0].oidc[0].issuer

#   depends_on = [aws_eks_cluster.osdu_eks_cluster_regional]

#   tags = {
#     Name = "bsp-eks-cluster1-oidc-provider"
#   }
# }

# Output the EKS cluster details
output "osdu_eks_cluster_arn_regional" {
  value       = aws_eks_cluster.osdu_eks_cluster_regional.arn
  description = "ARN of the OSDU regional EKS cluster"
  depends_on  = [aws_eks_cluster.osdu_eks_cluster_regional]
}

output "osdu_eks_cluster_endpoint" {
  value       = aws_eks_cluster.osdu_eks_cluster_regional.endpoint
  description = "Endpoint for the OSDU regional EKS cluster"
  depends_on  = [aws_eks_cluster.osdu_eks_cluster_regional]
}

output "osdu_eks_cluster_name" {
  value       = aws_eks_cluster.osdu_eks_cluster_regional.name
  description = "Name of the OSDU regional EKS cluster"
}



# Create aws-auth ConfigMap to allow worker nodes to join
resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.osdu_worker_node_role_regional.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
  }

  depends_on = [
    aws_eks_cluster.osdu_eks_cluster_regional,
    aws_iam_role.osdu_worker_node_role_regional
  ]
}

# Wait for auth ConfigMap to be applied before creating nodes
resource "time_sleep" "wait_for_auth" {
  depends_on = [kubernetes_config_map_v1.aws_auth]
  create_duration = "30s"
}

# # EKS Access Entry for worker nodes (EKS 1.23+)
# resource "aws_eks_access_entry" "osdu_worker_nodes" {
#   cluster_name      = aws_eks_cluster.osdu_eks_cluster_regional.name
#   principal_arn     = aws_iam_role.osdu_worker_node_role_regional.arn
#   kubernetes_groups = ["system:bootstrappers", "system:nodes"]
#   type              = "STANDARD"

#   depends_on = [
#     aws_eks_cluster.osdu_eks_cluster_regional,
#     aws_iam_role.osdu_worker_node_role_regional
#   ]

#   tags = {
#     Name        = "osdu-worker-nodes-access"
#     Environment = var.osdu_env
#   }
# }
