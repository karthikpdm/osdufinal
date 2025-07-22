# Configuring the EBS CSI Driver for nodes to write to EBS volume
data "tls_certificate" "osdu_certificate" {
  url        = aws_eks_cluster.osdu_eks_cluster.identity[0].oidc[0].issuer
  depends_on = [aws_eks_cluster.osdu_eks_cluster]
}

# Configuring the open-id provider for EBS CSI Driver
resource "aws_iam_openid_connect_provider" "osdu_openid_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.osdu_certificate.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.osdu_eks_cluster.identity[0].oidc[0].issuer
  depends_on      = [aws_eks_cluster.osdu_eks_cluster]
}

# Roles for the EBS CSI Driver
data "aws_iam_policy_document" "osdu_csi_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.osdu_openid_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.osdu_openid_provider.arn]
      type        = "Federated"
    }
  }
  depends_on = [aws_iam_openid_connect_provider.osdu_openid_provider]
}

# Apply the policy to the role
resource "aws_iam_role" "osdu_ebs_csi_driver_role" {
  assume_role_policy = data.aws_iam_policy_document.osdu_csi_policy.json
  name               = "osdu_ebs_csi_driver_role"
}

resource "aws_iam_role_policy_attachment" "osdu_ebs_csi_driver_policy" {
  role       = aws_iam_role.osdu_ebs_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Configuring the EBS CSI Driver
resource "aws_eks_addon" "osdu_csi_addon" {
  cluster_name             = var.eks_cluster_name
  addon_name               = var.csi_ebs_driver_name
  addon_version            = var.csi_ebs_driver_version
  service_account_role_arn = aws_iam_role.osdu_ebs_csi_driver_role.arn

  depends_on = [
    aws_instance.osdu_istio_node,
    aws_instance.osdu_backend_node,
    aws_instance.osdu_frontend_node
  ]
}

# Configure storage class for osdu
resource "kubernetes_storage_class" "osdu_ebs_storage" {
  metadata {
    name = "osdu-ebs-storage"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"
  parameters = {
    type   = "gp2"
    fsType = "ext4"
  }

  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = "true"

  depends_on = [aws_eks_addon.osdu_csi_addon]
}
