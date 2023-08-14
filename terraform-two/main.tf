resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.cluster_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  dns_prefix            = var.cluster_name
  node_resource_group  = "${var.cluster_name}-nodes"

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

resource "azurerm_log_analytics_workspace" "aks_logs_workspace" {
  name                = "${var.cluster_name}-log-analytics"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
}


resource "azurerm_monitor_diagnostic_setting" "aks_logs" {
  name               = "aksLogs"
  target_resource_id = azurerm_kubernetes_cluster.aks_cluster.id

  log {
    category = "kube-apiserver"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "kube-audit"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  # Add more log categories as needed

  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs_workspace.id
}

resource "helm_release" "argo" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "3.35.4"
  namespace  = "argocd"
  create_namespace = true
}


resource "helm_release" "argocd-apps" {
  depends_on = [helm_release.argo, azurerm_kubernetes_cluster.aks_cluster]
  chart      = "argocd-apps"
  name       = "argocd-apps"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  values = [file("${path.module}/values/argo.yaml")]
}

resource "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }

    port {
      port        = 443
      target_port = "https"
    }

    type = "LoadBalancer"
    load_balancer_ip = azurerm_public_ip.static_ip.ip_address
  }
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
}


resource "azurerm_public_ip" "static_ip" {
  name                = var.static_ip_name
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.aks_rg.name
  allocation_method  = "Static"
}

resource "azurerm_lb" "load_balancer" {
  name                = var.load_balancer_name
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = var.resource_group_location

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.static_ip.id
  }

  tags = {
        environment = "dev"
    }

}




resource "azurerm_lb_backend_address_pool" "argocd_backend_pool" {
  name            = "argocd-backend-pool"
  loadbalancer_id = azurerm_lb.load_balancer.id
}

resource "azurerm_lb_rule" "argocd_lb_rule" {
  name                           = "argocd-lb-rule"
#   resource_group_name            = azurerm_resource_group.aks_rg.name
  loadbalancer_id                = azurerm_lb.load_balancer.id
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.argocd_backend_pool.id]
  frontend_ip_configuration_name = "PublicIPAddress"
  frontend_port                  = 443
  backend_port                   = 443
  protocol                       = "Tcp"
  idle_timeout_in_minutes        = 5
  enable_floating_ip             = false
}

resource "azurerm_dns_zone" "dns_zone" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.aks_rg.name
}

resource "azurerm_dns_a_record" "subdomain" {
  name                = var.subdomain_name
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.aks_rg.name
  ttl                 = 300

  records = [azurerm_public_ip.static_ip.ip_address]
}


resource "azurerm_network_security_group" "argocd_nsg" {
  name                = "argocd-nsg"
  location            = azurerm_kubernetes_cluster.aks_cluster.location
  resource_group_name = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}

resource "azurerm_network_security_rule" "argocd_nsg_rule" {
  name                        = "argocd-nsg-rule"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
  network_security_group_name = azurerm_network_security_group.argocd_nsg.name
}



