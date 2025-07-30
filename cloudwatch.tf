locals {
  fluent_bit_yaml = <<YAML
input:
  tail:
    parser: containerd
cloudWatchLogs:
  enabled: true
  #match: "kube.*"
  region: ${var.aws_region}
  logGroupTemplate: "/aws/eks/${aws_eks_cluster.osdu_eks_cluster_regional.name}/logs/$kubernetes['namespace_name']"
  #logStreamTemplate: $kubernetes['container_name']
  #logStreamName: $kubernetes['container_name']
  logStreamPrefix: "fluentbit."
  #logKey: log
kinesis:
  enabled: false
firehose:
  enabled: false
opensearch:
  enabled: false
rbac:
  create: false
filters:
  kubernetes:
    enabled: true
    match: kube.*
    kubeTagPrefix: "kube.var.log.containers."
    mergeLog: On
    keepLog: On
    k8sLoggingParser: containerd
    k8sLoggingExclude: false
service:
  extraParsers: |
    [PARSER]
        Name        containerd
        Format      regex
        Regex       ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
    [MULTILINE_PARSER]
        name multiline_logs
        type regex
        rule      "start_state"   "/^(\d+\-\d+\-\d+T\d+\:\d+\:\d+\.\d+)(.*)/"         "cont"
        rule      "cont"          "/^(?!(\d+\-\d+\-\d+T\d+\:\d+\:\d+\.\d+).*$).*/"   "cont"
additionalFilters: |
  [FILTER]
      Name                  multiline
      Match                 kube.*
      multiline.key_content log
      multiline.parser      multiline_logs
YAML
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    annotations = {
      name = "monitoring"
    }

    name = "monitoring"
  }
}

resource "kubernetes_service_account" "fluent-bit" {
  automount_service_account_token = true
  metadata {
    name        = "aws-for-fluent-bit"
    namespace   = kubernetes_namespace.monitoring.id
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.fluent-bit.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-for-fluent-bit"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_service_account" "cloudwatch-metrics" {
  automount_service_account_token = true
  metadata {
    name        = "aws-cloudwatch-metrics"
    namespace   = kubernetes_namespace.monitoring.id
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cloudwatch-metrics.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-cloudwatch-metrics"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "fluent-bit" {
  chart      = "aws-for-fluent-bit"
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  version    = "0.1.32"
  namespace  = kubernetes_namespace.monitoring.id

  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.fluent-bit.metadata[0].name
  }

  values = [local.fluent_bit_yaml]
}

resource "helm_release" "aws-cloudwatch-metrics" {
  chart      = "aws-cloudwatch-metrics"
  name       = "aws-cloudwatch-metrics"
  repository = "https://aws.github.io/eks-charts"
  namespace  = kubernetes_namespace.monitoring.id

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.osdu_eks_cluster_regional.name
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.cloudwatch-metrics.metadata[0].name
  }
}

resource "aws_iam_policy" "aws_cloudwatch" {
  name        = "AWSCloudwatchIAMPolicy"
  path        = "/"
  description = "policy for aws cloudwatch"
  policy      = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "firehose:PutRecordBatch"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "logs:PutLogEvents",
          "Resource" : "arn:aws:logs:*:*:log-group:*:*:*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:log-group:*"
        },
        {
          "Effect" : "Allow",
          "Action" : "logs:CreateLogGroup",
          "Resource" : "*"
        }
      ]
    })
    
  tags = {
    Name = "AWSCloudwatchIAMPolicy"
  }
}

resource "aws_iam_role" "fluent-bit" {
  name = "AmazonEKSFluentbitRole-${var.osdu_env}"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Federated" : "${aws_iam_openid_connect_provider.osdu_openid_provider.arn}"
          },
          "Action" : "sts:AssumeRoleWithWebIdentity",
          "Condition" = {
            "StringEquals" = {
              "${replace(aws_iam_openid_connect_provider.osdu_openid_provider.url, "https://", "")}:sub" = "system:serviceaccount:${kubernetes_namespace.monitoring.id}:aws-for-fluent-bit"
              "${replace(aws_iam_openid_connect_provider.osdu_openid_provider.url, "https://", "")}:aud" = "sts.amazonaws.com"
            }
          }
        }
      ]
    })
    
  tags = {
    Name = "AmazonEKSFluentbitRole-${var.osdu_env}"
  }
}

resource "aws_iam_role" "cloudwatch-metrics" {
  name = "AmazonEKSCloudwatchMetricsRole-${var.osdu_env}"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Federated" : "${aws_iam_openid_connect_provider.osdu_openid_provider.arn}"
          },
          "Action" : "sts:AssumeRoleWithWebIdentity",
          "Condition" = {
            "StringEquals" = {
              "${replace(aws_iam_openid_connect_provider.osdu_openid_provider.url, "https://", "")}:sub" = "system:serviceaccount:${kubernetes_namespace.monitoring.id}:aws-cloudwatch-metrics"
              "${replace(aws_iam_openid_connect_provider.osdu_openid_provider.url, "https://", "")}:aud" = "sts.amazonaws.com"
            }
          }
        }
      ]
    })
    
  tags = {
    Name = "AmazonEKSCloudwatchMetricsRole-${var.osdu_env}"
  }
}

resource "aws_iam_role_policy_attachment" "aws-fluent-bit" {
  role       = aws_iam_role.fluent-bit.name
  policy_arn = aws_iam_policy.aws_cloudwatch.arn
}

data "aws_iam_policy" "cloudwatch-agent-policy" {
  name = "CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy" "cloudwatch-agent-custom-policy" {
  name        = "AWSCloudwatchMetricsIAMPolicy"
  path        = "/"
  description = "Custom policy for aws cloudwatch metrics ec2 tags"
  policy      = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : ["ec2:DescribeVolumes", "ec2:DescribeTags"],
          "Resource" : "*",
          "Effect" : "Allow"
        }
      ]
    })
    
  tags = {
    Name = "AWSCloudwatchMetricsIAMPolicy"
  }
}

resource "aws_iam_role_policy_attachment" "aws-cloudwatch-metrics-CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.cloudwatch-metrics.name
  policy_arn = data.aws_iam_policy.cloudwatch-agent-policy.arn
}

resource "aws_iam_role_policy_attachment" "aws-cloudwatch-metrics-AWSCloudwatchMetricsIAMPolicy" {
  role       = aws_iam_role.cloudwatch-metrics.name
  policy_arn = aws_iam_policy.cloudwatch-agent-custom-policy.arn
}

resource "aws_cloudwatch_log_group" "fluent-bit" {
  name              = "/aws/eks/${aws_eks_cluster.osdu_eks_cluster_regional.name}/fluentbit"
  retention_in_days = 365
  
  # kms_key_id  = data.aws_kms_key.cloudwatch-log-group.arn

  tags = {
    Name = "${var.eks_cluster_name}-eks-cluster-logs-${var.osdu_env}"
  }
}