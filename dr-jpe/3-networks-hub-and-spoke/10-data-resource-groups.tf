data "azurerm_resource_group" "platform" {
  provider = azurerm.platform
  for_each = { for key, row in local.resource_groups_all : key => row if row.subscription_key == "platform" }
  name     = each.value.name
}

data "azurerm_resource_group" "dev" {
  provider = azurerm.dev
  for_each = { for key, row in local.resource_groups_all : key => row if row.subscription_key == "dev" }
  name     = each.value.name
}
