terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }


  backend "azurerm" {
    resource_group_name  = "sa"
    storage_account_name = "123456909090"
    container_name       = "dev-tfstate"
    key                  = "dev-core-infra.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  common_tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "infrastructure-hub"
    Owner       = "cloud-engineering"
  }
} #