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


resource "azurerm_dns_a_record" "example" {
  name                = "app2"
  zone_name           = var.dns_zone_name
  resource_group_name = "dns-zone"
  ttl                 = 300
  records             = [azurerm_public_ip.test_ip.ip_address]
}