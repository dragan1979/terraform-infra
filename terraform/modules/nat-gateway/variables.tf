variable "nat_name" {
  type        = string
}

variable "location" {
  type        = string
}

variable "resource_group_name" {
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
}

variable allocation_metod {
  type        = string
  default     = ""
  description = "Nat gateway allocation method"
}

variable "sku" {    
  type        = string
  default     = ""
  description = "Nat gateway SKU"
}

variable vnet_aks_subnet_id {
  type        = string
  default     = ""
  description = "AKS Subnet ID for NAT Gateway association"
}

variable vnet_cicd_subnet_id {
  type        = string
  default     = ""
  description = "CI/CD Subnet ID for NAT Gateway association"
}
