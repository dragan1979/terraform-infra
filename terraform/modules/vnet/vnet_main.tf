resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = merge(var.tags, { "Component" = "Virtual Network" })

}

# The Private Subnet (For CI/CD VM)
resource "azurerm_subnet" "cicd" {
  name                 = "snet-cicd"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.cicd_subnet_prefixes
   
}


# The Private Subnet (For AKS)
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.aks_subnet_prefixes
   
}



# The Bastion Subnet (Must be named exactly AzureBastionSubnet)
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.bastion_subnet_prefixes
   
}

# The public Jumpbox Subnet (For RDP access to VMs in private subnet. Not used by Bastion Host, which has its own dedicated subnet)
resource "azurerm_subnet" "public_jumpbox" {
  name                 = "snet-public-jumpbox"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.public_jumpbox_cidr
}

# postgres Subnet

resource "azurerm_subnet" "postgres" {
  name                 = "snet-postgres"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.postgres_subnet_prefixes

  delegation {
    name = "postgres-delegation"
    service_delegation {
      # No other resources (like VMs or Bastion) can live in that same subnet, it's reserved exclusively for postgres Flexible Server
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      # It grants the postgres service the right to join its internal resources to private subnet.
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


# Private Endpoint Subnet
# Unlike postgres, Private Endpoints do not require subnet delegation. 
# This means that the subnet can be in the same VNET as the private endpoint.
resource "azurerm_subnet" "pe_subnet" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.pe_subnet_prefixes
}

