# Install Karpenter HElM
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "v0.10.0"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_irsa.iam_role_arn
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_id
  }

  set {
    name  = "clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }
  depends_on = [
    module.eks
  ]
}

# Install Karpenter Initial Provisioner
resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: initial-provisioner
  spec:
    requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["on-demand"]
    provider:
      subnetSelector:
        karpenter.sh/discovery: ${var.name}
      securityGroupSelector:
        karpenter.sh/discovery: ${var.name}
      tags:
        karpenter.sh/discovery: ${var.name}
    ttlSecondsAfterEmpty: 30
  YAML
  depends_on = [
    helm_release.karpenter,
    module.eks
  ]
}

# Install Nginx Ingress Controller HELM
resource "helm_release" "nginx-controller" {
  namespace        = "ingress-nginx"
  create_namespace = true

  name       = "ingress-nginx-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  values = [
    "${file("helm-values/nginx-values.yaml")}"
  ]
  depends_on = [
    module.eks,
    helm_release.karpenter
  ]
}

# Install Kubecost HELM
resource "helm_release" "kubecost" {
  namespace        = "kubecost"
  create_namespace = true

  name       = "kubecost"
  repository = "https://kubecost.github.io/cost-analyzer/"
  chart      = "cost-analyzer"

  values = [
    "${file("helm-values/kubecost-values.yaml")}"
  ]

  depends_on = [
    module.eks,
    helm_release.nginx-controller,
    helm_release.karpenter
  ]
}

# Install Consul HELM
resource "helm_release" "consul" {
  namespace        = "consul"
  create_namespace = true

  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"

  values = [
    "${file("helm-values/consul-values.yaml")}"
  ]
  depends_on = [
    module.eks,
    helm_release.karpenter,
    helm_release.nginx-controller
  ]
}