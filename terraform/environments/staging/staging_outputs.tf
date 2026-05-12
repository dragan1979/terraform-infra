output "vnet_id" {
  value       = module.vnet.vnet_id
  description = "The ID of the Virtual Network"
}

output "vnet_name" {
  value       = module.vnet.vnet_name
  description = "The name of the Virtual Network"
}

output "vm_subnet_id" {
  value       = module.vnet.vm_subnet_id
  description = "The ID of the VM private subnet"
}

output "bastion_subnet_id" {
  value       = module.vnet.bastion_subnet_id
  description = "The ID of the Bastion subnet to be used by the Bastion Host module"
}

output "aks_subnet_id" {
  value       = module.vnet.aks_subnet_id
  description = "The ID of the AKS subnet to be used by the AKS module"
}