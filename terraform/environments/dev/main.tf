locals {
  # Base VNET: 10.0.0.0 to 10.0.3.255 (1,024 IPs)
  vnet_address_space = "10.0.0.0/22"

  # AKS Subnet: 10.0.0.0/24 (256 IPs. Uses 10.0.0.0 to 10.0.0.255)
  # Formula: 24 - 22 = 2 newbits. Grab the 0th block.
  aks_subnet_cidr = cidrsubnet(local.vnet_address_space, 2, 0)

  # Bastion Subnet: 10.0.1.0/26 (64 IPs. Uses 10.0.1.0 to 10.0.1.63)
  # Formula: 26 - 22 = 4 newbits. Grab the 4th block.
  bastion_cidr = cidrsubnet(local.vnet_address_space, 4, 4)

  # CI/CD VM Subnet: 10.0.1.64/29 (8 IPs. Uses 10.0.1.64 to 10.0.1.71)
  # Formula: 29 - 22 = 7 newbits. Grab the 40th block.
  cicd_subnet_cidr = cidrsubnet(local.vnet_address_space, 7, 40)

  # postgres Subnet: 10.0.1.80/28 (16 IPs. Uses 10.0.1.80 to 10.0.1.95)
  # Formula: 28 - 22 = 6 newbits. Grab the 25th block.
  postgres_subnet_cidr = cidrsubnet(local.vnet_address_space, 6, 25)

  # Private Endpoint Subnet: 10.0.1.96/28 (16 IPs)
  # Formula: 28 - 22 = 6 newbits. Grab the 26th block.
  pe_subnet_cidr = cidrsubnet(local.vnet_address_space, 6, 26)

  # Public Jumpbox Subnet: 10.0.1.112/28 (16 IPs. Uses 10.0.1.112 to 10.0.1.127)
  # Formula: 28 - 22 = 6 newbits. Grab the 27th block.
  public_jumpbox_cidr = cidrsubnet(local.vnet_address_space, 6, 28)

}


data "azurerm_client_config" "current" {}

variable "region" {
  type        = string
  description = "The region where resources will be deployed"
  default     = "swedencentral"
}

# Fetches the public IP address of the machine running Terraform
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}


resource "azurerm_resource_group" "network_rg" {
  name     = "rg-core-network"
  location = var.region
  tags     = local.common_tags
}

resource "azurerm_resource_group" "aks_rg" {
  name     = "aks-resource-group"
  location = var.region
  tags     = local.common_tags
}

resource "azurerm_resource_group" "vault_rg" {
  name     = "rg-security-hub"
  location = var.region
  tags     = local.common_tags
}

resource "azurerm_resource_group" "vm_rg" {
  name     = "vm-resource-group"
  location = var.region
  tags     = local.common_tags
}

resource "azurerm_resource_group" "postgres_rg" {
  name     = "postgres-resource-group"
  location = var.region
  tags     = local.common_tags
}


# Assign RBAC Admin scoped STRICTLY to the Key Vault Resource Group
resource "azurerm_role_assignment" "rg_rbac_admin" {
  scope                = azurerm_resource_group.vault_rg.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_resource_group.vault_rg]
}

# Assign Key Vault Security Officer scoped to the Key Vault Resource Group
resource "azurerm_role_assignment" "rg_kv_officer" {
  scope                = azurerm_resource_group.vault_rg.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_resource_group.vault_rg]
}


module "vnet" {
  source = "../../modules/vnet"

  vnet_name                = "vnet-hub"
  resource_group_name      = azurerm_resource_group.network_rg.name
  location                 = azurerm_resource_group.network_rg.location
  address_space            = [local.vnet_address_space]
  aks_subnet_prefixes      = [local.aks_subnet_cidr]
  bastion_subnet_prefixes  = [local.bastion_cidr]
  cicd_subnet_prefixes     = [local.cicd_subnet_cidr]
  postgres_subnet_prefixes = [local.postgres_subnet_cidr]
  pe_subnet_prefixes       = [local.pe_subnet_cidr]
  public_jumpbox_cidr      = [local.public_jumpbox_cidr]
  azure_key_vault_id       = module.keyvault.key_vault_id
  my_ip_address            = data.http.my_ip.response_body
  tags                     = merge(local.common_tags, { "Project" = "infrastructure-hub" })

}

 module "bastion" {
   source = "../../modules/bastion"

   bastion_name        = "bastion-hub"
   resource_group_name = azurerm_resource_group.network_rg.name
   location            = azurerm_resource_group.network_rg.location
   subnet_id           = module.vnet.bastion_subnet_id
   tags                = merge(local.common_tags, { "Project" = "infrastructure-hub" })
   depends_on = [module.vnet]
  }

module "nat_gateway" {
  source              = "../../modules/nat-gateway"
  nat_name            = "nat-gateway-hub"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  tags                = local.common_tags
  sku                 = "Standard"
  vnet_aks_subnet_id  = module.vnet.aks_subnet_id
  vnet_cicd_subnet_id = module.vnet.cicd_subnet_id

  depends_on = [module.vnet]
}

module "aks" {
  source              = "../../modules/aks"
  cluster_name        = "petclinic-aks"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "petclinic-aks"
  subnet_id           = module.vnet.aks_subnet_id
  tags                = merge(local.common_tags, { "Project" = "infrastructure-hub" })
  vm_size             = "Standard_B2s_v2"
  node_count          = 2
  depends_on          = [module.vnet, module.nat_gateway]
}




module "keyvault" {
  source              = "../../modules/keyvault"
  vault_name          = "kv-hub-prod-unique23456"
  resource_group_name = azurerm_resource_group.vault_rg.name
  location            = azurerm_resource_group.vault_rg.location
  vnet_id             = module.vnet.vnet_id
  pe_subnet_id        = module.vnet.pe_subnet_id
  admin_ip_address    = "${chomp(data.http.my_ip.response_body)}/32"

  # Pass your current Object ID and Tenant ID to the module
  tenant_id       = data.azurerm_client_config.current.tenant_id
  admin_object_id = data.azurerm_client_config.current.object_id
  # subscription_id     = data.azurerm_client_config.current.subscription_id
  tags = merge(local.common_tags, { "Project" = "infrastructure-hub" })


}

 module "cicd_vm" {
   source              = "../../modules/vm"
   vm_name             = "vm-cicd"
   resource_group_name = azurerm_resource_group.vm_rg.name
   location            = azurerm_resource_group.vm_rg.location
   subnet_id           = module.vnet.cicd_subnet_id
   vm_size             = "Standard_B1ms"
   aks_id              = module.aks.aks_id
   create_public_ip    = false
   is_cicd_agent       = true 
 }

module "jumpbox_vm" {
  source              = "../../modules/vm"
  vm_name             = "vm-jumpbox"
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = azurerm_resource_group.vm_rg.location
  subnet_id           = module.vnet.public_jumpbox_subnet_id
  vm_size             = "Standard_B2s_v2"
  create_public_ip    = true
  is_cicd_agent       = false
  aks_id              = module.aks.aks_id
}


module "postgres" {
  source              = "../../modules/database"
  resource_group_name = azurerm_resource_group.postgres_rg.name
  location            = azurerm_resource_group.postgres_rg.location
  postgres_version    = "14"
  sku_name            = "B_Standard_B1ms"
  storage_size_mb     = "32768" # 32 GB
  # Wiring the modules together
  vnet_id            = module.vnet.vnet_id
  postgres_subnet_id = module.vnet.postgres_subnet_id
  key_vault_id       = module.keyvault.key_vault_id
  tags               = merge(local.common_tags, { "Project" = "infrastructure-hub" })
  depends_on         = [module.vnet, module.keyvault]

}


# To securely connect AKS cluster to Azure Key Vault using Workload Identity, we need to build a "bridge of trust" between
# Kubernetes and Azure Entra ID (Active Directory).


# 1. Create the User-Assigned Managed Identity
# We don't want to use the AKS cluster's master identity, because then every pod in the cluster could read every secret.
# We create a dedicated "Petclinic Identity" so only the Petclinic app gets access. 
# It's a best practice to have one identity per application for better security and auditing.


resource "azurerm_user_assigned_identity" "petclinic_identity" {
  name                = "id-petclinic-dev"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  tags                = local.common_tags
}

# 2. Grant the Identity read access to Key Vault secrets (The "Permission")

# Even though the identity exists, it has zero access by default. 
# We must explicitly assign it the "Key Vault Secrets User" role so it can read (but not delete or overwrite) the database passwords.

resource "azurerm_role_assignment" "petclinic_kv_secrets_user" {
  # This targets the Key Vault you created in your module
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.petclinic_identity.principal_id
}

# Create the Federated Identity Credential (The "Trust Link")

# Azure needs to know who is allowed to access the "Petclinic Identity".
# This resource tells Azure: "If a pod in the dev namespace of my AKS cluster is using the petclinic-sa service account, trust it, and hand it the tokens for this identity."
resource "azurerm_federated_identity_credential" "petclinic_fic" {
  name                = "fic-petclinic-dev"
  resource_group_name = azurerm_resource_group.aks_rg.name
  audience            = ["api://AzureADTokenExchange"]

  # This grabs the OIDC URL from AKS cluster
  issuer    = module.aks.oidc_issuer_url
  parent_id = azurerm_user_assigned_identity.petclinic_identity.id

  # This exact string must match the Kubernetes Service Account you create later
  # Format: system:serviceaccount:<namespace>:<service-account-name>
  subject = "system:serviceaccount:dev:petclinic-sa"
}