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

resource "azurerm_lb_backend_address_pool" "test_pool" {
  name                = "BackendPool"
  loadbalancer_id    = azurerm_lb.test_load_balancer.id
}

resource "azurerm_lb_rule" "http_rule" {
  name                   = "HTTPRule"
  loadbalancer_id       = azurerm_lb.test_load_balancer.id
  protocol               = "Tcp"
  frontend_port          = 80
  backend_port           = 80
  frontend_ip_configuration_name = azurerm_lb.test_load_balancer.frontend_ip_configuration[0].name
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.test_pool.id]
}

resource "azurerm_lb_rule" "https_rule" {
  name                   = "HTTPSRule"
  loadbalancer_id       = azurerm_lb.test_load_balancer.id
  protocol               = "Tcp"
  frontend_port          = 443
  backend_port           = 443
  frontend_ip_configuration_name = azurerm_lb.test_load_balancer.frontend_ip_configuration[0].name
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.test_pool.id]
}

# data "azurerm_lb_backend_address_pool" "test_pool" {
#   name            = "BackendPool"
#   loadbalancer_id = azurerm_lb.test_load_balancer.id
# }

# data "azurerm_virtual_network" "aks_vnet" {
#   name                = "aks-vnet"
#   resource_group_name = azurerm_resource_group.aks_rg.name
# }


# resource "azurerm_lb_backend_address_pool_address" "test_pool_address" {
#   name                    = "BackendPoolAddress"
#   backend_address_pool_id = data.azurerm_lb_backend_address_pool.test_pool.id
#   virtual_network_id      = data.azurerm_virtual_network.aks_vnet.id
# #   backend_address_ip_configuration_id = azurerm_lb.test_load_balancer.frontend_ip_configuration[0].id
#   ip_address              = "10.0.0.1"
# }


