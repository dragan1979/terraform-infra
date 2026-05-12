output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The ID of the Virtual Network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
}

output "cicd_subnet_id" {
  value       = azurerm_subnet.cicd.id
  description = "The ID of the CI/CD private subnet"
}

output "bastion_subnet_id" {
  value       = azurerm_subnet.bastion.id
  description = "The ID of the Bastion subnet to be used by the Bastion Host module"
}

output "aks_subnet_id" {
  value       = azurerm_subnet.aks.id
  description = "The ID of the AKS subnet to be used by the AKS module"
}

output "pe_subnet_id" {
  value = azurerm_subnet.pe_subnet.id
  description = "The ID of the Private Endpoint subnet to be used by the Private Endpoint module"
}

output "postgres_subnet_id" {
  value = azurerm_subnet.postgres.id
  description = "The ID of the postgres subnet to be used by the postgres module"
}

output "public_jumpbox_subnet_id" {
  value = azurerm_subnet.public_jumpbox.id
  description = "The ID of the public jumpbox subnet to be used by the jumpbox module"
}