variable "vnet_name" {
  type        = string
  description = "The name of the Virtual Network"
}

variable "location" {
  type        = string
  description = "The Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group"
}

variable "address_space" {
  type        = list(string)
  description = "The address space for the VNET"
}

variable "cicd_subnet_prefixes" {
  type        = list(string)
  description = "The address prefixes for the CI/CD subnet"
}

variable "bastion_subnet_prefixes" {
  type        = list(string)
  description = "The address prefixes for the Bastion subnet"
}

variable "aks_subnet_prefixes" {
  type        = list(string)
  description = "The address prefixes for the AKS subnet"
}

variable "postgres_subnet_prefixes" {
  type        = list(string)
  description = "The address prefixes for the postgres subnet"
}

variable "pe_subnet_prefixes" {
  type        = list(string)
  default     = []
  description = "The address prefixes for the Private Endpoint subnet"
}

variable "pipeline_agent_subnet_prefixes" {
  type        = list(string)
  description = "The address prefixes for the Pipeline Agent subnet"
}

variable "public_jumpbox_cidr" {
  type        = list(string)
  description = "The address prefixes for the public jumpbox subnet"
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resources"
  default     = {}
}

variable "azure_key_vault_id" {
  type        = string
  default     = ""
  description = "The ID of the Azure Key Vault"
}

variable "my_ip_address" {
  type        = string
  description = "The public IP address allowed to bypass the Key Vault firewall"
}