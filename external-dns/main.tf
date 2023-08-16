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

resource "kubernetes_namespace" "test_deploy" {
  
  metadata {
    name = "test-deploy"
  }
}