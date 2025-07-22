# variable "outpost_region" {
#   type        = string
#   description = "The region where outpost is deployed"
#   default     = "ap-southeast-1"
# }

# variable "osdu_outpost_arn" {
#   type        = string
#   description = "The arn of outpost"
#   default     = "arn:aws:outposts:ap-southeast-1:481665108250:outpost/op-03effba8d01c4ade5"
# }

# variable "osdu_vpc_id" {
#   type        = string
#   description = "The VPC where OSDU is deployed"
#   default     = "vpc-05856fb88c3a2983e"
# }

# variable "osdu_subnet_id" {
#   type        = string
#   description = "The private subnet"
#   default     = "subnet-02a4a40d247e24866"
# }

# variable "eks_cluster_name" {
#   type        = string
#   description = "The EKS cluster name"
#   default     = "osdu_eks_cluster"
# }

# variable "csi_ebs_driver_name" {
#   type        = string
#   description = "EBS CSI Driver name"
#   default     = "aws-ebs-csi-driver"
# }

# variable "csi_ebs_driver_version" {
#   type        = string
#   description = "EBS CSI Driver version"
#   default     = "v1.35.0-eksbuild.1"
# }

# variable "eks_version" {
#   type        = string
#   description = "EKS version"
#   default     = "1.31"
# }

# variable "instance_type_worker" {
#   type        = string
#   description = "The worker node EC2 compute power"
#   default     = "m5.2xlarge"
# }

# variable "instance_type_controller" {
#   type        = string
#   description = "The controller node EC2 compute power"
#   default     = "m5.xlarge"
# }

# # We are using the Linux provided by AWS. It has auto bootstrap logic for nodes to join the cluster
# # If we use Ubuntu 22.4 image directly then we will need to do a lot of bootstrap related configurations
# # that are complex.

# variable "ami_id" {
#   type        = string
#   description = "We are using the Linux provided by AWS. It has auto bootstrap logic for nodes to join the cluster"
#   default     = "ami-02987219953aaf8e3"
# }

# variable "tar_istio_base" {
#   type        = string
#   description = "Istio base tar"
#   default     = "istio-base-1.21.0.tgz"
# }

# variable "tar_istiod" {
#   type        = string
#   description = "Istiod tar"
#   default     = "istiod-1.21.0.tgz"
# }

# variable "tar_istio_gateway" {
#   type        = string
#   description = "Istio gateway tar"
#   default     = "istio-gateway-1.21.0.tgz"
# }

# variable "tar_osdu_baremetal" {
#   type        = string
#   description = "OSDU helm bundle with all the comonents like osdu_microservices, keycloak, postgresql, minio, elasticsearch, rabbitmq, ariflow, redis"
#   default     = "osdu-gc-baremetal-0.27.2.tgz"
# }

# variable "osdu_env" {
#   type        = string
#   description = "Environment"
#   default     = "osdu"
# }

# variable "osdu_data_partition" {
#   type        = string
#   description = "The default partition that will be created"
#   default     = "osdu"
# }

# variable "osdu_proxy" {
#   type        = string
#   description = "Proxy used for image pulling"
#   default     = "http://158.161.77.145:8080"
# }

variable "pem_key_name" {
  type        = string
  description = "The pem key that wil l be required to ssh to this instance"
  default     = "bspnew"
}

# Additional variables (add to your variables.tf if not present)
variable "aws_region" {
  description = "AWS region for regional deployment"
  type        = string
  default     = "us-east-1"  # Change as needed
}




variable "eks_cluster_name" {
  type        = string
  description = "The EKS cluster name"
  default     = "osdu_eks_cluster"
}

variable "csi_ebs_driver_name" {
  type        = string
  description = "EBS CSI Driver name"
  default     = "aws-ebs-csi-driver"
}

variable "csi_ebs_driver_version" {
  type        = string
  description = "EBS CSI Driver version"
  default     = "v1.35.0-eksbuild.1"
}

variable "eks_version" {
  type        = string
  description = "EKS version"
  default     = "1.31"
}

variable "instance_type_worker" {
  type        = string
  description = "The worker node EC2 compute power"
  default     = "m5.2xlarge"
}

variable "instance_type_controller" {
  type        = string
  description = "The controller node EC2 compute power"
  default     = "m5.xlarge"
}

variable "osdu_env" {
  type        = string
  description = "Environment"
  default     = "osdu"
}

# variable "ami_id" {
#   type        = string
#   description = "We are using the Linux provided by AWS. It has auto bootstrap logic for nodes to join the cluster"
#   # default     = "ami-02987219953aaf8e3"
#   default  = "ami-084a44881bcb0d54c"
# }


variable "tar_istio_base" {
  type        = string
  description = "Istio base tar"
  default     = "istio-base-1.21.0.tgz"
}

variable "tar_istiod" {
  type        = string
  description = "Istiod tar"
  default     = "istiod-1.21.0.tgz"
}

variable "tar_istio_gateway" {
  type        = string
  description = "Istio gateway tar"
  default     = "istio-gateway-1.21.0.tgz"
}

variable "tar_osdu_baremetal" {
  type        = string
  description = "OSDU helm bundle with all the comonents like osdu_microservices, keycloak, postgresql, minio, elasticsearch, rabbitmq, ariflow, redis"
  default     = "osdu-gc-baremetal-0.27.2.tgz"
}










