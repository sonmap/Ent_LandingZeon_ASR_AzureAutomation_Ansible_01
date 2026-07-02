resource "azurerm_virtual_network" "platform" {
  provider            = azurerm.platform
  for_each            = local.platform_networks
  name                = each.value.name
  location            = data.azurerm_resource_group.platform[each.value.resource_group_key].location
  resource_group_name = data.azurerm_resource_group.platform[each.value.resource_group_key].name
  address_space       = [each.value.address_space]
  tags                = merge(local.tags, { Purpose = each.value.purpose })
}

resource "azurerm_virtual_network" "dev" {
  provider            = azurerm.dev
  for_each            = local.dev_networks
  name                = each.value.name
  location            = data.azurerm_resource_group.dev[each.value.resource_group_key].location
  resource_group_name = data.azurerm_resource_group.dev[each.value.resource_group_key].name
  address_space       = [each.value.address_space]
  tags                = merge(local.tags, { Purpose = each.value.purpose })
}

resource "azurerm_subnet" "platform" {
  provider             = azurerm.platform
  for_each             = local.platform_subnets
  name                 = each.value.name
  resource_group_name  = data.azurerm_resource_group.platform[local.networks_all[each.value.network_key].resource_group_key].name
  virtual_network_name = azurerm_virtual_network.platform[each.value.network_key].name
  address_prefixes     = [each.value.address_prefix]
}

resource "azurerm_subnet" "dev" {
  provider             = azurerm.dev
  for_each             = local.dev_subnets
  name                 = each.value.name
  resource_group_name  = data.azurerm_resource_group.dev[local.networks_all[each.value.network_key].resource_group_key].name
  virtual_network_name = azurerm_virtual_network.dev[each.value.network_key].name
  address_prefixes     = [each.value.address_prefix]
}
