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

# Read outputs from Phase 1 - Core Infrastructure tfstate file

data "terraform_remote_state" "core" {
  backend = "azurerm"
  config = {
    resource_group_name  = "sa"
    storage_account_name = "123456909090"
    container_name       = "staging-tfstate"
    key                  = "staging-core-infra.tfstate"
  }
}



# Fetch the Key Vault name, Key Vault RG name, Postgres Server name and Postgres RG name from the Core Infra outputs (tfstate file from Phase 1)

data "azurerm_key_vault" "kv" {
  name                = data.terraform_remote_state.core.outputs.key_vault_name
  resource_group_name = data.terraform_remote_state.core.outputs.keyvault_rg_name
}

# Fetch the App User Password
data "azurerm_key_vault_secret" "app_password" {
  name         = "postgres-standard-user-password"
  key_vault_id = data.azurerm_key_vault.kv.id
}


data "azurerm_postgresql_flexible_server" "pg" {
  name                = data.terraform_remote_state.core.outputs.postgres_server_name
  resource_group_name = data.terraform_remote_state.core.outputs.postgres_rg_name
}

data "azurerm_key_vault_secret" "pg_admin_password" {
  name         = "postgres-admin-password"
  key_vault_id = data.azurerm_key_vault.kv.id
}

provider "postgresql" {
  host     = data.azurerm_postgresql_flexible_server.pg.fqdn
  port     = 5432
  username = data.azurerm_postgresql_flexible_server.pg.administrator_login
  password = data.azurerm_key_vault_secret.pg_admin_password.value
  sslmode  = "require"
  # Bypass the Azure permission block
  superuser = false
}


module "postgres" {
  source            = "../../../modules/database-internals"
  app_user_password = data.azurerm_key_vault_secret.app_password.value
}