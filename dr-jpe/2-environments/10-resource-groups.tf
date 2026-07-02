resource "azurerm_resource_group" "platform" {
  provider = azurerm.platform
  for_each = local.platform_resource_groups

  name     = each.value.name
  location = each.value.location
  tags     = merge(local.tags, { Workload = each.value.workload, Purpose = each.value.purpose })
}

resource "azurerm_resource_group" "dev" {
  provider = azurerm.dev
  for_each = local.dev_resource_groups

  name     = each.value.name
  location = each.value.location
  tags     = merge(local.tags, { Workload = each.value.workload, Purpose = each.value.purpose })
}
