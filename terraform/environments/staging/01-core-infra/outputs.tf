output "vnet_id" {
  value       = module.vnet.vnet_id
  description = "The ID of the Virtual Network"
}

output "vnet_name" {
  value       = module.vnet.vnet_name
  description = "The name of the Virtual Network"
}

output "cicd_subnet_id" {
  value       = module.vnet.cicd_subnet_id
  description = "The ID of the CI/CD private subnet"
}

output "bastion_subnet_id" {
  value       = module.vnet.bastion_subnet_id
  description = "The ID of the Bastion subnet to be used by the Bastion Host module"
}

output "aks_subnet_id" {
  value       = module.vnet.aks_subnet_id
  description = "The ID of the AKS subnet to be used by the AKS module"
}

output "petclinic_identity_client_id" {
  value       = azurerm_user_assigned_identity.petclinic_identity.client_id
  description = "COPY THIS VALUE: Paste it into the azure.workload.identity/client-id annotation in your petclinic-sa.yaml"
}

output "azure_tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure Tenant ID"
}


output "key_vault_name" {
  value = module.keyvault.key_vault_name
}

output "keyvault_rg_name" {
  value = azurerm_resource_group.vault_rg.name
}

output "postgres_server_name" {
  value = module.postgres.postgres_server_name
}

output "postgres_rg_name" {
  value = azurerm_resource_group.postgres_rg.name
}