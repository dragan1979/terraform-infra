output "bastion_id" {
  value       = azurerm_bastion_host.bastion.id
  description = "The ID of the Bastion Host"
}

output "public_ip_address" {
  value       = azurerm_public_ip.bastion_pip.ip_address
  description = "The Public IP address of the Bastion Host"
}