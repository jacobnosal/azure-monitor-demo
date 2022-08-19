terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.15.0"
    }

    azapi = {
      source  = "azure/azapi"
      version = "~>0.1"
    }
  }

  required_version = ">= 0.14"
}