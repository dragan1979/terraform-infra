resource "azurerm_public_ip" "nat_pip" {
  name                = "pip-${var.nat_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = var.sku
  tags                = var.tags
}

resource "azurerm_nat_gateway" "nat" {
  name                    = var.nat_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = var.sku
  idle_timeout_in_minutes = 4
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

# Associate with the AKS Subnet
resource "azurerm_subnet_nat_gateway_association" "aks_nat" {
  subnet_id      = var.vnet_aks_subnet_id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

# Associate with the Private (VM) Subnet
resource "azurerm_subnet_nat_gateway_association" "vm_nat" {
  subnet_id      = var.vnet_cicd_subnet_id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}