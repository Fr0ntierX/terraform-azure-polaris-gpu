provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.22.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.3.0"
    }
  }
}

data "azurerm_client_config" "current" {}
