variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region"
  type        = string
}

variable "vnet_id" {
  description = "The ID of the Virtual Network (for the DNS link)"
  type        = string
}

variable "postgres_subnet_id" {
  description = "The ID of the delegated PostgreSQL Subnet"
  type        = string
}

variable "key_vault_id" {
  description = "The ID of the Key Vault to store the admin password"
  type        = string
}

variable "server_name" {
  description = "The globally unique name for the PostgreSQL server"
  type        = string
  default     = "postgres-infra-hub-dev" 
}

variable "postgres_version" {
  description = "The version of PostgreSQL to use"
  type        = string
  default     = "14"
}

variable "sku_name" {
  description = "The SKU name for the PostgreSQL server"
  type        = string
  default     = "B_Standard_B1ms"
} 

variable "storage_size_mb" {
  description = "The storage size for the PostgreSQL server in MB"
  type        = number
  default     = 32768 # 32 GB
}

variable "tags" {
  type    = map(string)
  default = {}
}