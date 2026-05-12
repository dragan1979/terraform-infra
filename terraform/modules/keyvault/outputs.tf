output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.kv.id
  # This forces any module requesting this ID to wait for the sleep timer!
  #depends_on  = [time_sleep.wait_for_rbac]
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "The URI used by applications to access the Key Vault"
}