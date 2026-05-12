variable "bastion_name" {
  type        = string
  description = "The name of the Bastion Host"
}

variable "location" {
  type        = string
  description = "The Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the AzureBastionSubnet created by the VNET module"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resources"
  default     = {}
}