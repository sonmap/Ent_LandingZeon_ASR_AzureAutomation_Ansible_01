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
