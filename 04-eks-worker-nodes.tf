# #  Worker Node role
# resource "aws_iam_role" "osdu_worker_node_role" {
#   name = "osdu_worker_node_role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })

#   tags = {
#     Name = "osdu_worker_node_role"
#   }
# }

# resource "aws_iam_role_policy_attachment" "osdu_worker_node_policy_attach" {
#   role       = aws_iam_role.osdu_worker_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }

# resource "aws_iam_role_policy_attachment" "osdu_eks_cni_policy_attach" {
#   role       = aws_iam_role.osdu_worker_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }

# resource "aws_iam_role_policy_attachment" "osdu_eks_registry_policy_attach" {
#   role       = aws_iam_role.osdu_worker_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# resource "aws_iam_instance_profile" "osdu_node_profile" {
#   name = "osdu_node_profile"
#   role = aws_iam_role.osdu_worker_node_role.name
# }

# data "aws_subnet" "osdu_subnet" {
#   id = var.osdu_subnet_id
# }

# data "aws_security_group" "eks_cluster_sg" {
#   filter {
#     name   = "group-name"
#     values = ["eks-cluster-sg-${var.eks_cluster_name}*"]
#   }

#   filter {
#     name   = "vpc-id"
#     values = [var.osdu_vpc_id]
#   }
#   depends_on = [aws_eks_cluster.osdu_eks_cluster]
# }

# # Creation of the EC2 instance1 for hosting IStio + Keycloak
# resource "aws_instance" "osdu_istio_node" {
#   ami                         = var.ami_id
#   instance_type               = var.instance_type_worker
#   subnet_id                   = var.osdu_subnet_id
#   associate_public_ip_address = false
#   iam_instance_profile        = aws_iam_instance_profile.osdu_node_profile.name
#   vpc_security_group_ids      = [data.aws_security_group.eks_cluster_sg.id]
#   key_name                    = var.pem_key_name


#   user_data = base64encode(join("\n", [
#     "#!/bin/bash",
#     "set -o xtrace",
#     "",
#     "# Configure proxy if required",
#     "export http_proxy='${var.osdu_proxy}'",
#     "export https_proxy='${var.osdu_proxy}'",
#     "echo 'export http_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
#     "echo 'export https_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
#     "",
#     "# Bootstrap the node into the EKS cluster",
#     "echo '[BOOT] Running bootstrap.sh...' >> /var/log/user-data.log",
#     "/etc/eks/bootstrap.sh '${var.eks_cluster_name}' --kubelet-extra-args '--node-labels=node-role=osdu_istio_node' >> /var/log/user-data.log 2>&1",
#     "echo '[BOOT] Finished bootstrap.sh with exit code $?' >> /var/log/user-data.log",
#     "",
#     "systemctl enable kubelet >> /var/log/user-data.log 2>&1",
#     "echo '[BOOT] Enabled kubelet at: $(date)' >> /var/log/user-data.log",
#     "",
#     "echo '[BOOT] UserData script completed at: $(date)' >> /var/log/user-data.log"
#   ]))

#   tags = {
#     Name                                            = "osdu_istio_node"
#     "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
#     BU_Name                                         = "BSP-OSDU-Account"
#   }

#   depends_on = [
#     aws_eks_cluster.osdu_eks_cluster,
#     aws_iam_role_policy_attachment.osdu_worker_node_policy_attach,
#     aws_iam_role_policy_attachment.osdu_eks_cni_policy_attach,
#     aws_iam_role_policy_attachment.osdu_eks_registry_policy_attach
#   ]
# }


# # Labeling the nodes for Istio
# resource "null_resource" "label_istio_nodes" {
#   provisioner "local-exec" {
#     command     = <<EOT
# aws eks update-kubeconfig --region ${var.outpost_region} --name ${var.eks_cluster_name}

# nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
# for node in $nodes; do
#   if [[ "$node" == *osdu_istio_node* ]]; then
#     echo "[INFO] Labeling node: $node"
#     kubectl label node "$node" node-role=osdu_istio_node --overwrite
#     echo "[INFO] Labelling completed successfully."
#   fi
# done
# EOT
#     interpreter = ["/bin/bash", "-c"]
#   }

#   depends_on = [
#     aws_instance.osdu_istio_node
#   ]
# }

# # Creation of the EC2 instance1 for hosting hosting minio + postgres + elasticsearch + RabbitMQ
# resource "aws_instance" "osdu_backend_node" {
#   ami                         = var.ami_id
#   instance_type               = var.instance_type_worker
#   subnet_id                   = var.osdu_subnet_id
#   associate_public_ip_address = false
#   iam_instance_profile        = aws_iam_instance_profile.osdu_node_profile.name
#   vpc_security_group_ids      = [data.aws_security_group.eks_cluster_sg.id]
#   key_name                    = var.pem_key_name

#   user_data = base64encode(join("\n", [
#     "#!/bin/bash",
#     "set -o xtrace",
#     "",
#     "# Configure proxy if required",
#     "export http_proxy='${var.osdu_proxy}'",
#     "export https_proxy='${var.osdu_proxy}'",
#     "echo 'export http_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
#     "echo 'export https_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
#     "",
#     "# Bootstrap the node into the EKS cluster",
#     "echo '[BOOT] Running bootstrap.sh...' >> /var/log/user-data.log",
#     "/etc/eks/bootstrap.sh '${var.eks_cluster_name}' --kubelet-extra-args '--node-labels=node-role=osdu_backend_node' >> /var/log/user-data.log 2>&1",
#     "echo '[BOOT] Finished bootstrap.sh with exit code $?' >> /var/log/user-data.log",
#     "",
#     "systemctl enable kubelet >> /var/log/user-data.log 2>&1",
#     "echo '[BOOT] Enabled kubelet at: $(date)' >> /var/log/user-data.log",
#     "",
#     "echo '[BOOT] UserData script completed at: $(date)' >> /var/log/user-data.log"
#   ]))

#   tags = {
#     Name                                            = "osdu_backend_node"
#     "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
#     BU_Name                                         = "BSP-OSDU-Account"
#   }

#   depends_on = [
#     aws_eks_cluster.osdu_eks_cluster,
#     aws_iam_role_policy_attachment.osdu_worker_node_policy_attach,
#     aws_iam_role_policy_attachment.osdu_eks_cni_policy_attach,
#     aws_iam_role_policy_attachment.osdu_eks_registry_policy_attach
#   ]
# }

# # Labeling the nodes for Backend
# resource "null_resource" "label_backend_nodes" {
#   provisioner "local-exec" {
#     command     = <<EOT
# aws eks update-kubeconfig --region ${var.outpost_region} --name ${var.eks_cluster_name}

# nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
# for node in $nodes; do
#   if [[ "$node" == *osdu_backend_node* ]]; then
#     echo "[INFO] Labeling node: $node"
#     kubectl label node "$node" node-role=osdu_backend_node --overwrite
#   fi
# done
# EOT
#     interpreter = ["/bin/bash", "-c"]
#   }

#   depends_on = [
#     aws_instance.osdu_backend_node
#   ]
# }

# # Creation of the EC2 instance1 for hosting OSDU Microservices + Airflow + Redis
# resource "aws_instance" "osdu_frontend_node" {
#   ami                         = var.ami_id
#   instance_type               = var.instance_type_worker
#   subnet_id                   = var.osdu_subnet_id
#   associate_public_ip_address = false
#   iam_instance_profile        = aws_iam_instance_profile.osdu_node_profile.name
#   vpc_security_group_ids      = [data.aws_security_group.eks_cluster_sg.id]
#   key_name                    = var.pem_key_name

#   user_data = base64encode(join("\n", [
#     "#!/bin/bash",
#     "set -o xtrace",
#     "",
#     "# Configure proxy if required",
#     "export http_proxy='${var.osdu_proxy}'",
#     "export https_proxy='${var.osdu_proxy}'",
#     "echo 'export http_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
#     "echo 'export https_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
#     "",
#     "# Bootstrap the node into the EKS cluster",
#     "echo '[BOOT] Running bootstrap.sh...' >> /var/log/user-data.log",
#     "/etc/eks/bootstrap.sh '${var.eks_cluster_name}' --kubelet-extra-args '--node-labels=node-role=osdu_frontend_node' >> /var/log/user-data.log 2>&1",
#     "echo '[BOOT] Finished bootstrap.sh with exit code $?' >> /var/log/user-data.log",
#     "",
#     "systemctl enable kubelet >> /var/log/user-data.log 2>&1",
#     "echo '[BOOT] Enabled kubelet at: $(date)' >> /var/log/user-data.log",
#     "",
#     "echo '[BOOT] UserData script completed at: $(date)' >> /var/log/user-data.log"
#   ]))

#   tags = {
#     Name                                            = "osdu_frontend_node"
#     "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
#     BU_Name                                         = "BSP-OSDU-Account"
#   }

#   depends_on = [
#     aws_eks_cluster.osdu_eks_cluster,
#     aws_iam_role_policy_attachment.osdu_worker_node_policy_attach,
#     aws_iam_role_policy_attachment.osdu_eks_cni_policy_attach,
#     aws_iam_role_policy_attachment.osdu_eks_registry_policy_attach
#   ]
# }

# # Labeling the nodes for Frontend
# resource "null_resource" "label_frontend_nodes" {
#   provisioner "local-exec" {
#     command     = <<EOT
# aws eks update-kubeconfig --region ${var.outpost_region} --name ${var.eks_cluster_name}

# nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
# for node in $nodes; do
#   if [[ "$node" == *osdu_frontend_node* ]]; then
#     echo "[INFO] Labeling node: $node"
#     kubectl label node "$node" node-role=osdu_frontend_node --overwrite
#   fi
# done
# EOT
#     interpreter = ["/bin/bash", "-c"]
#   }

#   depends_on = [
#     aws_instance.osdu_frontend_node
#   ]
# }




# Worker Node IAM role for regional deployment
# Data source to get the latest EKS-optimized AMI
# Data source to get the latest EKS-optimized AMI
data "aws_ssm_parameter" "eks_ami_id" {
  name = "/aws/service/eks/optimized-ami/${var.eks_version}/amazon-linux-2/recommended/image_id"
}

# Worker Node IAM role for regional deployment
resource "aws_iam_role" "osdu_worker_node_role_regional" {
  name = "osdu_worker_node_role_regional"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "osdu_worker_node_role_regional"
    Environment = var.osdu_env
  }
}

# Attach required policies for worker nodes
resource "aws_iam_role_policy_attachment" "osdu_worker_node_policy_attach_regional" {
  role       = aws_iam_role.osdu_worker_node_role_regional.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "osdu_eks_cni_policy_attach_regional" {
  role       = aws_iam_role.osdu_worker_node_role_regional.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "osdu_eks_registry_policy_attach_regional" {
  role       = aws_iam_role.osdu_worker_node_role_regional.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM instance profile for worker nodes
resource "aws_iam_instance_profile" "osdu_node_profile_regional" {
  name = "osdu_node_profile_regional1"
  role = aws_iam_role.osdu_worker_node_role_regional.name
}

# Regional EC2 instance for hosting Istio + Keycloak (AZ1)
resource "aws_instance" "osdu_istio_node_regional_az1" {
  ami                         = data.aws_ssm_parameter.eks_ami_id.value
  instance_type               = var.instance_type_worker
  subnet_id                   = data.aws_subnet.private_az1.id  # Reference from datasource.tf
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.osdu_node_profile_regional.name
  vpc_security_group_ids      = [aws_security_group.eks_nodes.id]  # Reference from datasource.tf
  key_name                    = var.pem_key_name

  user_data = base64encode(join("\n", [
    "#!/bin/bash",
    "set -o xtrace",
    "",
    # "# Configure proxy if required",
    # "export http_proxy='${var.osdu_proxy}'",
    # "export https_proxy='${var.osdu_proxy}'",
    # "echo 'export http_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
    # "echo 'export https_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
    # "",
    "# Bootstrap the node into the EKS cluster",
    "echo '[BOOT] Running bootstrap.sh...' >> /var/log/user-data.log",
    "/etc/eks/bootstrap.sh '${var.eks_cluster_name}' --kubelet-extra-args '--node-labels=node-role=osdu_istio_node,availability-zone=az1' >> /var/log/user-data.log 2>&1",
    "echo '[BOOT] Finished bootstrap.sh with exit code $?' >> /var/log/user-data.log",
    "",
    "systemctl enable kubelet >> /var/log/user-data.log 2>&1",
    "echo '[BOOT] Enabled kubelet at: $(date)' >> /var/log/user-data.log",
    "",
    "echo '[BOOT] UserData script completed at: $(date)' >> /var/log/user-data.log"
  ]))

  tags = {
    Name                                                         = "osdu_istio_node_regional_az1"
    "kubernetes.io/cluster/${var.eks_cluster_name}"             = "owned"
    BU_Name                                                      = "BSP-OSDU-Account"
    Environment                                                  = var.osdu_env
    Project                                                      = "OSDU"
    AvailabilityZone                                            = "az1"
  }

  depends_on = [
    aws_eks_cluster.osdu_eks_cluster_regional,
    aws_iam_role_policy_attachment.osdu_worker_node_policy_attach_regional,
    aws_iam_role_policy_attachment.osdu_eks_cni_policy_attach_regional,
    aws_iam_role_policy_attachment.osdu_eks_registry_policy_attach_regional,
    time_sleep.wait_for_auth
  ]
}

# Regional EC2 instance for hosting Backend services (AZ2)
resource "aws_instance" "osdu_backend_node_regional_az2" {
  ami                         = data.aws_ssm_parameter.eks_ami_id.value
  instance_type               = var.instance_type_worker
  subnet_id                   = data.aws_subnet.private_az2.id  # Reference from datasource.tf
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.osdu_node_profile_regional.name
  vpc_security_group_ids      = [aws_security_group.eks_nodes.id]  # Reference from datasource.tf
  key_name                    = var.pem_key_name

  user_data = base64encode(join("\n", [
    "#!/bin/bash",
    "set -o xtrace",
    "",
    # "# Configure proxy if required",
    # "export http_proxy='${var.osdu_proxy}'",
    # "export https_proxy='${var.osdu_proxy}'",
    # "echo 'export http_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
    # "echo 'export https_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
    # "",
    "# Bootstrap the node into the EKS cluster",
    "echo '[BOOT] Running bootstrap.sh...' >> /var/log/user-data.log",
    "/etc/eks/bootstrap.sh '${var.eks_cluster_name}' --kubelet-extra-args '--node-labels=node-role=osdu_backend_node,availability-zone=az2' >> /var/log/user-data.log 2>&1",
    "echo '[BOOT] Finished bootstrap.sh with exit code $?' >> /var/log/user-data.log",
    "",
    "systemctl enable kubelet >> /var/log/user-data.log 2>&1",
    "echo '[BOOT] Enabled kubelet at: $(date)' >> /var/log/user-data.log",
    "",
    "echo '[BOOT] UserData script completed at: $(date)' >> /var/log/user-data.log"
  ]))

  tags = {
    Name                                                         = "osdu_backend_node_regional_az2"
    "kubernetes.io/cluster/${var.eks_cluster_name}"             = "owned"
    BU_Name                                                      = "BSP-OSDU-Account"
    Environment                                                  = var.osdu_env
    Project                                                      = "OSDU"
    AvailabilityZone                                            = "az2"
  }

  depends_on = [
    aws_eks_cluster.osdu_eks_cluster_regional,
    aws_iam_role_policy_attachment.osdu_worker_node_policy_attach_regional,
    aws_iam_role_policy_attachment.osdu_eks_cni_policy_attach_regional,
    aws_iam_role_policy_attachment.osdu_eks_registry_policy_attach_regional,
    time_sleep.wait_for_auth
  ]
}

# Regional EC2 instance for hosting Frontend services (AZ1 for redundancy)
resource "aws_instance" "osdu_frontend_node_regional_az1" {
  ami                         = data.aws_ssm_parameter.eks_ami_id.value
  instance_type               = var.instance_type_worker
  subnet_id                   = data.aws_subnet.private_az1.id  # Reference from datasource.tf
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.osdu_node_profile_regional.name
  vpc_security_group_ids      = [aws_security_group.eks_nodes.id]  # Reference from datasource.tf
  key_name                    = var.pem_key_name

  user_data = base64encode(join("\n", [
    "#!/bin/bash",
    "set -o xtrace",
    "",
    # "# Configure proxy if required",
    # "export http_proxy='${var.osdu_proxy}'",
    # "export https_proxy='${var.osdu_proxy}'",
    # "echo 'export http_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
    # "echo 'export https_proxy=${var.osdu_proxy}' >> /etc/profile.d/proxy.sh",
    # "",
    "# Bootstrap the node into the EKS cluster",
    "echo '[BOOT] Running bootstrap.sh...' >> /var/log/user-data.log",
    "/etc/eks/bootstrap.sh '${var.eks_cluster_name}' --kubelet-extra-args '--node-labels=node-role=osdu_frontend_node,availability-zone=az1' >> /var/log/user-data.log 2>&1",
    "echo '[BOOT] Finished bootstrap.sh with exit code $?' >> /var/log/user-data.log",
    "",
    "systemctl enable kubelet >> /var/log/user-data.log 2>&1",
    "echo '[BOOT] Enabled kubelet at: $(date)' >> /var/log/user-data.log",
    "",
    "echo '[BOOT] UserData script completed at: $(date)' >> /var/log/user-data.log"
  ]))

  tags = {
    Name                                                         = "osdu_frontend_node_regional_az1"
    "kubernetes.io/cluster/${var.eks_cluster_name}"             = "owned"
    BU_Name                                                      = "BSP-OSDU-Account"
    Environment                                                  = var.osdu_env
    Project                                                      = "OSDU"
    AvailabilityZone                                            = "az1"
  }

  depends_on = [
    aws_eks_cluster.osdu_eks_cluster_regional,
    aws_iam_role_policy_attachment.osdu_worker_node_policy_attach_regional,
    aws_iam_role_policy_attachment.osdu_eks_cni_policy_attach_regional,
    aws_iam_role_policy_attachment.osdu_eks_registry_policy_attach_regional,
    time_sleep.wait_for_auth
  ]
}

# Node labeling for Istio nodes
resource "null_resource" "label_istio_nodes_regional" {
  provisioner "local-exec" {
    command     = <<EOT
aws eks update-kubeconfig --region us-east-1 --name ${var.eks_cluster_name}

nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
for node in $nodes; do
  if [[ "$node" == *osdu_istio_node_regional* ]]; then
    echo "[INFO] Labeling node: $node"
    kubectl label node "$node" node-role=osdu_istio_node --overwrite
    echo "[INFO] Labeling completed successfully for $node."
  fi
done
EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    aws_instance.osdu_istio_node_regional_az1
  ]
}

# Node labeling for Backend nodes
resource "null_resource" "label_backend_nodes_regional" {
  provisioner "local-exec" {
    command     = <<EOT
aws eks update-kubeconfig --region us-east-1 --name ${var.eks_cluster_name}

nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
for node in $nodes; do
  if [[ "$node" == *osdu_backend_node_regional* ]]; then
    echo "[INFO] Labeling node: $node"
    kubectl label node "$node" node-role=osdu_backend_node --overwrite
    echo "[INFO] Labeling completed successfully for $node."
  fi
done
EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    aws_instance.osdu_backend_node_regional_az2
  ]
}

# Node labeling for Frontend nodes
resource "null_resource" "label_frontend_nodes_regional" {
  provisioner "local-exec" {
    command     = <<EOT
aws eks update-kubeconfig --region us-east-1 --name ${var.eks_cluster_name}

nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
for node in $nodes; do
  if [[ "$node" == *osdu_frontend_node_regional* ]]; then
    echo "[INFO] Labeling node: $node"
    kubectl label node "$node" node-role=osdu_frontend_node --overwrite
    echo "[INFO] Labeling completed successfully for $node."
  fi
done
EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    aws_instance.osdu_frontend_node_regional_az1
  ]
}

# Outputs for worker nodes
output "osdu_worker_nodes_regional" {
  description = "OSDU Regional Worker Node details"
  value = {
    istio_node_az1 = {
      instance_id   = aws_instance.osdu_istio_node_regional_az1.id
      private_ip    = aws_instance.osdu_istio_node_regional_az1.private_ip
      subnet_id     = aws_instance.osdu_istio_node_regional_az1.subnet_id
    }
    backend_node_az2 = {
      instance_id   = aws_instance.osdu_backend_node_regional_az2.id
      private_ip    = aws_instance.osdu_backend_node_regional_az2.private_ip
      subnet_id     = aws_instance.osdu_backend_node_regional_az2.subnet_id
    }
    frontend_node_az1 = {
      instance_id   = aws_instance.osdu_frontend_node_regional_az1.id
      private_ip    = aws_instance.osdu_frontend_node_regional_az1.private_ip
      subnet_id     = aws_instance.osdu_frontend_node_regional_az1.subnet_id
    }
  }
}

