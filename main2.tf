# provider "azurerm" {
#   features {}
# }

# resource "azurerm_resource_group" "example" {
#   name     = "example-resources"
#   location = "East US"
# }

# resource "azurerm_kubernetes_cluster" "example" {
#   name                = "example-aks-cluster"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   dns_prefix          = "exampleaks"

#   default_node_pool {
#     name       = "default"
#     node_count = 1
#     vm_size    = "Standard_DS2_v2"
#   }
# }

# resource "azurerm_subnet" "example" {
#   name                 = "example-subnet"
#   resource_group_name  = azurerm_resource_group.example.name
#   virtual_network_name = azurerm_kubernetes_cluster.example.network_profile[0].name
#   address_prefixes     = ["10.1.0.0/24"]
# }

# resource "azurerm_subnet_network_security_group_association" "example" {
#   subnet_id                 = azurerm_subnet.example.id
#   network_security_group_id = azurerm_network_security_group.example.id
# }

# resource "azurerm_public_ip" "example" {
#   name                = "example-publicip"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   allocation_method   = "Static"
# }

# resource "azurerm_lb" "example" {
#   name                = "example-lb"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   sku                 = "Standard"

#   frontend_ip_configuration {
#     name                 = "PublicIPAddress"
#     public_ip_address_id = azurerm_public_ip.example.id
#   }

#   dynamic "frontend_ip_configuration" {
#     for_each = azurerm_subnet.example
#     content {
#       name                 = "InternalSubnet"
#       subnet_id            = azurerm_subnet.example[frontend_ip_configuration.key].id
#     }
#   }
# }

# resource "azurerm_network_security_group" "example" {
#   name                = "example-nsg"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
# }

# resource "azurerm_network_interface" "example" {
#   count               = azurerm_kubernetes_cluster.example.node_resource_group.count
#   name                = "example-nic-${count.index}"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.example.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.example.id

#     # Add Network Security Group
#     network_security_group_id = azurerm_network_security_group.example.id
#   }
# }

# resource "azurerm_kubernetes_cluster_node_pool" "example" {
#   name                 = "example"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
#   node_count           = 1
#   vm_size              = "Standard_DS2_v2"
#   os_disk_size_gb     = 30
#   type                 = "VirtualMachineScaleSets"
# }

# resource "azurerm_network_interface_backend_address_pool_association" "example" {
#   count               = azurerm_kubernetes_cluster.example.node_resource_group.count
#   network_interface_id = azurerm_network_interface.example[count.index].id
#   ip_configuration_name = "internal"
#   backend_address_pool_id = azurerm_lb.example.backend_address_pool[0].id
# }
