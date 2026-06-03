# Bastion requires a Static, Standard Public IP
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-${var.bastion_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(
    var.tags,
    {
      Component = "Bastion-Public-IP"
    }
  )
}

# The Bastion Host itself
resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard" # Required for file transfer / native client

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = merge(
    var.tags,
    {
      Component = "Bastion-Service"
    }
  )
}