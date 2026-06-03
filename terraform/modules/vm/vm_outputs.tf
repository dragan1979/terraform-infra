output "private_ip" {
  value = azurerm_linux_virtual_machine.vm.private_ip_address
}

output "public_ip" {
  value       = var.create_public_ip ? azurerm_public_ip.pip[0].ip_address : null
  description = "The public IP address of the VM, if created."
}