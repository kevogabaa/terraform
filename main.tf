# Define variables if not already defined

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_group_location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = "Standard_DS2_v2"
    type                = "VirtualMachineScaleSets"
    # availability_zones  = [1, 2, 3]
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 4
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    load_balancer_sku = "standard"
    network_plugin    = "kubenet"
  }
}

# Create DNS zone
resource "azurerm_dns_zone" "argocd_dns" {
  name                = "ogaba.io"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create DNS record for ArgoCD
resource "azurerm_dns_a_record" "argocd_dns_record" {
  name                = "argo"
  zone_name           = azurerm_dns_zone.argocd_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
#   type                = "A"
  records             = [azurerm_public_ip.argocd_public_ip.ip_address]
  depends_on          = [azurerm_kubernetes_cluster.aks, azurerm_public_ip.argocd_public_ip ]  # Wait for AKS cluster creation
}

# Add Load Balancer for ArgoCD
resource "azurerm_public_ip" "argocd_public_ip" {
  name                = "argocd-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method  = "Static"
  sku = "Standard"
  ddos_protection_mode = "Enabled"  
}

resource "azurerm_network_security_group" "argocd_nsg" {
  name                = "argocd-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "cert_manager" {
  source = "terraform-iaac/cert-manager/kubernetes"
  cluster_issuer_email = "ogaba@ogaba.io"  

  certificates = {
      argo-cd-certificate = {
      namespace = "argocd"
      common_name = "argo.ogaba.io"
      dns_names   = ["argo.ogaba.io", "www.argo.ogaba.io"]
    }
  }

  depends_on = [ azurerm_public_ip.argocd_public_ip, azurerm_network_security_group.argocd_nsg, kubernetes_namespace.namespace_argocd ]

}

resource "kubernetes_namespace" "namespace_argocd" {
  
  metadata {
    name = "argo-cd"
  }

  depends_on = [ azurerm_kubernetes_cluster.aks ]
}

# ArgoCD Installation

resource "helm_release" "argocd" {
  chart            = "argo-cd"
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  create_namespace = true
  version          = "3.35.4"
  values = [
    file("values/argo-server.yaml"),
  ]
  depends_on = [azurerm_public_ip.argocd_public_ip, azurerm_kubernetes_cluster.aks]  # Wait for LB and certificate
}

resource "helm_release" "argocd-apps" {
  depends_on = [helm_release.argocd, azurerm_kubernetes_cluster.aks]
  chart      = "argocd-apps"
  name       = "argocd-apps"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  values = [
    file("values/argo-apps.yaml")
  ]
}


resource "kubernetes_namespace" "test_deploy" {
  
  metadata {
    name = "test-deploy"
  }

  depends_on = [ azurerm_kubernetes_cluster.aks ]
}


