resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.1.3"

  namespace        = "ingress-basic"
  create_namespace = true

  set {
    name  = "controller.replicaCount"
    value = "2"
  }
  set {
    name  = "controller.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = var.resource_group_name
  }
}

  
resource "helm_release" "argo" {
  depends_on = [ azurerm_kubernetes_cluster.aks_cluster] #, azurerm_public_ip.argocd_public_ip ]
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "3.35.4"
  namespace  = "argocd"
  create_namespace = true
}

resource "helm_release" "argocd-apps" {
  depends_on = [helm_release.argo]
  chart      = "argocd-apps"
  name       = "argocd-apps"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  values = [file("${path.module}/values/argo.yaml")]
}

locals {
  cert_manager_vars = {
    podlabel_identity_use = true,
    service_account_identity_use = true,
  }
  cert_manager_values = templatefile(
    "${path.module}/values/cert_manager.yaml.tmpl",
    local.cert_manager_vars
  )
}


resource "helm_release" "cert_manager" {
  depends_on = [ azurerm_kubernetes_cluster.aks_cluster ]
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version = "1.12.3"
  namespace  = "cert-manager"
  create_namespace = true
  values    = [local.cert_manager_values]
}

data "azurerm_client_config" "current" {}


locals {
  external_dns_vars = {
    resource_group  = "dns-zone",
    tenant_id       = data.azurerm_client_config.current.tenant_id,
    subscription_id = data.azurerm_client_config.current.subscription_id,
    log_level       = "debug",
    domain          = var.dns_zone_name,
    client_id     = var.service_principal_appid,
    client_secret = var.service_principal_password,
    use_managed_identity_extension = "false",
  }

  external_dns_values = templatefile(
    "${path.module}/values/external.yaml.tmpl",
    local.external_dns_vars
  )
}

resource "helm_release" "external_dns" {
  depends_on = [ azurerm_kubernetes_cluster.aks_cluster ]
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version = "6.23.3"
  namespace  = "external-dns"
  create_namespace = true
  values     = [local.external_dns_values]
}
