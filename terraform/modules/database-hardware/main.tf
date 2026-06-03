
locals {
  petclinic_db_names = ["customers", "vets", "visits"]
}


# --- Private DNS Zone & VNet Link ---

resource "azurerm_private_dns_zone" "pg_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg_vnet_link" {
  name                  = "pg-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.pg_dns.name
  virtual_network_id    = var.vnet_id 
}

# --- Secure Password Generation ---
resource "random_password" "pg_admin" {
  length           = 20
  special          = true
  override_special = "_%@"
}

resource "random_password" "app_user_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# --- Key Vault Secret Storage ---
resource "azurerm_key_vault_secret" "pg_password_secret" {
  name         = "postgres-admin-password"
  value        = random_password.pg_admin.result
  key_vault_id = var.key_vault_id 
}

resource "azurerm_key_vault_secret" "pg_standard_user_password_secret" {
  name         = "postgres-standard-user-password"
  value        = random_password.app_user_password.result
  key_vault_id = var.key_vault_id 
}

resource "azurerm_postgresql_flexible_server" "pg_server" {
  name                   = var.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  
  administrator_login    = "pgadmin"
  administrator_password = random_password.pg_admin.result
  zone                   = "1"

  sku_name               = var.sku_name
  version                = var.postgres_version
  storage_mb             = var.storage_size_mb
  
  public_network_access_enabled = false
  delegated_subnet_id           = var.postgres_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.pg_dns.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.pg_vnet_link]
}

# Create all databases in one go
resource "azurerm_postgresql_flexible_server_database" "dbs" {
  for_each  = toset(local.petclinic_db_names)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.pg_server.id
  charset   = "UTF8"
  collation = "en_US.utf8"

  depends_on = [azurerm_postgresql_flexible_server.pg_server]
}