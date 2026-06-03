output "postgres_server_name" {
  description = "The name of the Postgres Flexible Server"
  value       = azurerm_postgresql_flexible_server.pg_server.name
}

output "postgres_server_fqdn" {
  description = "The Fully Qualified Domain Name of the Postgres server"
  value       = azurerm_postgresql_flexible_server.pg_server.fqdn
}

output "admin_user" {
  value = azurerm_postgresql_flexible_server.pg_server.administrator_login
}

output "admin_password" {
  value     = azurerm_postgresql_flexible_server.pg_server.administrator_password
  sensitive = true
}