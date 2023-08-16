
resource "azurerm_network_security_group" "test_nsg" {
  name                = "test-nsg"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}


resource "azurerm_network_security_rule" "test_allow_http" {
  name                        = "test-allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.aks_rg.name
  network_security_group_name = azurerm_network_security_group.test_nsg.name
}

resource "azurerm_network_security_rule" "test_allow_https" {
  name                        = "test-allow-https"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.aks_rg.name
  network_security_group_name = azurerm_network_security_group.test_nsg.name
}

resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

# Create subnets

resource "azurerm_subnet" "test_subnet" {
  name                 = "test-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
