resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  depends_on = [ azurerm_resource_group.aks_rg ]
  name                = var.cluster_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  dns_prefix            = var.cluster_name
  node_resource_group  = "${var.cluster_name}-nodes"
  workload_identity_enabled = true
  oidc_issuer_enabled = true
  sku_tier = "Standard"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dev"
  }
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

resource "azurerm_public_ip" "test_ip" {
  name                = "TestPublicIp"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  allocation_method   = "Static"
  sku                = "Standard"
  sku_tier = "Regional"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_lb" "test_load_balancer" {
  name                = "TestLoadBalancer"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                = "Standard"
  sku_tier = "Regional"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.test_ip.id
  }
}

resource "azurerm_dns_a_record" "example" {
  name                = "app2"
  zone_name           = var.dns_zone_name
  resource_group_name = "dns-zone"
  ttl                 = 300
  records             = [azurerm_public_ip.test_ip.ip_address]
}

# resource "azurerm_public_ip" "argocd_public_ip" {
#   name                = "argocd-public-ip"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   location            = azurerm_resource_group.aks_rg.location
#   allocation_method   = "Static"
#   sku                = "Standard"
#   sku_tier = "Regional"

#   tags = {
#     environment = "Production"
#   }
# }


# resource "azurerm_lb" "argocd_load_balancer" {
#   name                = "argocd-load-balancer"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   sku                = "Standard"
#   sku_tier = "Regional"

#   frontend_ip_configuration {
#     name                 = "PublicIPAddress"
#     public_ip_address_id = azurerm_public_ip.argocd_public_ip.id
#   }
# }

# resource "azurerm_dns_a_record" "argocd_dns" {
#   name                = "argocd"
#   zone_name           = var.dns_zone_name
#   resource_group_name = "dns-zone"
#   ttl                 = 300
#   records             = [azurerm_public_ip.argocd_public_ip.ip_address]
# }
  
resource "helm_release" "argo" {
  depends_on = [ azurerm_kubernetes_cluster.aks_cluster] #, azurerm_public_ip.argocd_public_ip ]
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "3.35.4"
  namespace  = "argocd"
  create_namespace = true

  # set {
  #   name = "server.service.type"
  #   value = "LoadBalancer"
  # }
}

resource "helm_release" "argocd-apps" {
  depends_on = [helm_release.argo]
  chart      = "argocd-apps"
  name       = "argocd-apps"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  values = [file("${path.module}/values/argo.yaml")]
}