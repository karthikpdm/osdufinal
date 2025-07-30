# locals {
#   cluster-name = "${var.project_name}-eks-cluster-${var.env}"
  
#   aws_account_id    = data.aws_caller_identity.current.account_id
#   partition         = data.aws_partition.current.partition
#   provider_url_oidc = substr("${aws_eks_cluster.eks.identity[0].oidc[0].issuer}",8,length("${aws_eks_cluster.eks.identity[0].oidc[0].issuer}")-1)

#   karpenter_yaml = <<YAML
# clusterName: "${aws_eks_cluster.eks.name}"
# clusterEndpoint: "${aws_eks_cluster.eks.endpoint}"
# hostNetwork: true

# serviceAccount:
#   create: true
#   annotations:
#     eks.amazonaws.com/role-arn: "${aws_iam_role.karpenter.arn}"

# aws:
#   defaultInstanceProfile: "${var.project_name}-eks-worker-profile-${var.env}"

# YAML

#   karpenter_nodepool_yaml = <<YAML
# apiVersion: karpenter.sh/v1beta1
# kind: NodePool
# metadata:
#   name: default
# spec:
#   disruption:
#     consolidateAfter: 30s
#     consolidationPolicy: WhenEmpty
#     expireAfter: Never
#   limits:
#     cpu: "${var.karpenter_vcpu}"
#     memory: "${var.karpenter_memory}Gi"
#   template:
#     metadata:
#         labels:
#          clusterName: ${aws_eks_cluster.eks.name}
#     spec:
#       nodeClassRef:
#         name: default
#       requirements:
#       - key: node.kubernetes.io/instance-type
#         operator: In
#         values: [${var.instance_type}]
#       - key: karpenter.sh/capacity-type
#         operator: In
#         values: ["on-demand"]
#       - key: kubernetes.io/arch
#         operator: In
#         values: ["amd64"]

# YAML

#   karpenter_nodeclass_yaml = <<YAML
# apiVersion: karpenter.k8s.aws/v1beta1
# kind: EC2NodeClass
# metadata:
#   name: default
# spec:
#   amiFamily: "${var.ami_type}"
#   amiSelectorTerms:
#     - name: "amazon-eks-node-${var.eks_version}-*"  
#       owner: "602401143452" 
#   role: KarpenterRole-${aws_eks_cluster.eks.name}
#   userData: |
#       #!/bin/bash -xe

#       /etc/eks/bootstrap.sh ${aws_eks_cluster.eks.name} --kubelet-extra-args '--register-with-taints="karpenter.sh/unregistered=true:NoExecute"'

#       yum install -y "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"
#       systemctl start amazon-ssm-agent
#   securityGroupSelectorTerms:
#   - tags:
#       aws:eks:cluster-name: ${aws_eks_cluster.eks.name}
#   subnetSelectorTerms:
#   - tags:
#       Name: "pw-private-subnet-az*-${var.env}"
#   tags:
#     intent: apps
#     managed-by: karpenter
#     Name: "${var.project_name}-eks-karpenter-nodes-${var.env}"
#     project: ${var.project_name}
#     track: ${var.map_tagging["track"]}
#     env: ${var.env}
#     map-migrated: ${var.map_tagging["map-migrated"]}
    
#   blockDeviceMappings:
#     - deviceName: /dev/xvda
#       ebs:
#         volumeSize: "${var.disk_size}Gi"
#         volumeType: gp3
#         deleteOnTermination: true
#         encrypted: true
#         tags:
#           Name: "${var.project_name}-eks-karpenter-volume-${var.env}"
#   metadataOptions:
#     httpEndpoint: enabled
#     httpTokens: required
#     httpPutResponseHopLimit: 2
    
# YAML

#   fluent_bit_yaml = <<YAML
# input:
#   parser: containerd
# cloudWatchLogs:
#   enabled: true
#   #match: "kube.*"
#   region: ${var.aws_region}
#   logGroupName: ${aws_cloudwatch_log_group.fluent-bit.name}
#   #logGroupTemplate: ${aws_cloudwatch_log_group.fluent-bit.name}
#   #logStreamName: $kubernetes['container_name']
#   #logStreamTemplate: $kubernetes['container_name']
#   logStreamPrefix: "fluentbit."
#   #logKey: log
# kinesis:
#   enabled: false
# firehose:
#   enabled: false
# opensearch:
#   enabled: false
# rbac:
#   create: false
# service:
#   extraParsers: |
#     [PARSER]
#         Name        containerd
#         Format      regex
#         Regex       ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$
#         Time_Key    time
#         Time_Format %Y-%m-%dT%H:%M:%S.%L%z
#     [MULTILINE_PARSER]
#         name multiline_logs
#         type regex
#         rule      "start_state"   "/^(\d+\-\d+\-\d+T\d+\:\d+\:\d+\.\d+)(.*)/"         "cont"
#         rule      "cont"          "/^(?!(\d+\-\d+\-\d+T\d+\:\d+\:\d+\.\d+).*$).*/"   "cont"
# additionalFilters: |
#   [FILTER]
#       Name                  multiline
#       Match                 kube.*
#       multiline.key_content log
#       multiline.parser      multiline_logs
# YAML

# node-userdata = <<USERDATA
#     #!/bin/bash -xe

# /etc/eks/bootstrap.sh ${aws_eks_cluster.eks.name}

# yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
# systemctl start amazon-ssm-agent

# USERDATA
# }
