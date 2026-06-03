variable "vault_name" {
  type        = string
  description = "The name of the Key Vault. MUST BE GLOBALLY UNIQUE!"
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_id" {
  type = string
  description = "The ID of the Virtual Network"
}

variable "pe_subnet_id" {
  type = string
  description = "The ID of the Private Endpoint subnet for Key Vault"
}

variable "admin_ip_address" {
  type        = string
  description = "The public IP address allowed to bypass the Key Vault firewall"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable tenant_id {
  type        = string
  description = "The Azure tenant ID"
}

variable admin_object_id {
  type        = string
  description = "The Azure object ID of the user allowed to access the Key Vault"
}

# variable subscription_id {
#   type        = string
#   description = "The Azure subscription ID"
# }