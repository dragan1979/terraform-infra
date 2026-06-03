terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }

    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.25.0" # Current stable version for 2026
    }

  }


  backend "azurerm" {
    resource_group_name  = "sa"
    storage_account_name = "123456909090"
    container_name       = "staging-tfstate"
    key                  = "staging-data-plane.tfstate"
  }
}

provider "azurerm" {
  features {}
}


locals {
  common_tags = {
    Environment = "staging"
    ManagedBy   = "Terraform"
    Project     = "infrastructure-hub"
    Owner       = "cloud-engineering"
  }
}