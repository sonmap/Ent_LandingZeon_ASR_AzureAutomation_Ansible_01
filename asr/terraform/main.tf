terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.67"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "asr" {
  name     = var.asr_resource_group_name
  location = var.vault_location
  tags     = local.tags
}

resource "azurerm_recovery_services_vault" "asr" {
  name                = var.recovery_services_vault_name
  location            = azurerm_resource_group.asr.location
  resource_group_name = azurerm_resource_group.asr.name
  sku                 = "Standard"
  soft_delete_enabled = true
  tags                = local.tags
}

resource "azurerm_storage_account" "cache" {
  name                     = var.cache_storage_account_name
  resource_group_name      = var.primary_cache_resource_group_name
  location                 = var.primary_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.tags
}

resource "azurerm_automation_account" "dr" {
  name                = var.automation_account_name
  location            = azurerm_resource_group.asr.location
  resource_group_name = azurerm_resource_group.asr.name
  sku_name            = "Basic"
  tags                = local.tags
}

locals {
  tags = {
    Environment = var.environment
    Purpose     = "asr-dr-automation"
    Owner       = var.owner
  }
}

# Note:
# ASR replicated VM, network mapping, protection container mapping, and recovery plan
# can be configured by Terraform provider resources or by the Azure CLI scripts under ../scripts.
# In many enterprise environments the CLI/PowerShell path is easier to control because ASR
# object names are generated from fabric/protection-container discovery results.
