resource "azurerm_route_table" "dev" {
  provider            = azurerm.dev
  for_each            = local.dev_routes
  name                = each.value.route_table_name
  location            = data.azurerm_resource_group.dev[each.value.resource_group_key].location
  resource_group_name = data.azurerm_resource_group.dev[each.value.resource_group_key].name
  tags                = merge(local.tags, { Purpose = each.value.purpose })

  route {
    name                   = each.value.route_name
    address_prefix         = each.value.address_prefix
    next_hop_type          = each.value.next_hop_type
    next_hop_in_ip_address = each.value.next_hop_type == local.network_config.virtual_appliance_next_hop_type ? each.value.next_hop_in_ip_address : null
  }
}

resource "azurerm_subnet_route_table_association" "dev" {
  provider       = azurerm.dev
  for_each       = local.dev_routes
  subnet_id      = azurerm_subnet.dev[each.value.subnet_key].id
  route_table_id = azurerm_route_table.dev[each.key].id
}

resource "azurerm_private_dns_zone" "zones" {
  provider            = azurerm.platform
  for_each            = local.private_dns_zones_all
  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.platform[each.value.resource_group_key].name
  tags                = local.tags
}

resource "azurerm_virtual_network_peering" "platform_to_dev" {
  provider                  = azurerm.platform
  for_each                  = local.dev_networks
  name                      = "peer-hub-to-${each.key}"
  resource_group_name       = data.azurerm_resource_group.platform["hub"].name
  virtual_network_name      = azurerm_virtual_network.platform["hub"].name
  remote_virtual_network_id = azurerm_virtual_network.dev[each.key].id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "dev_to_platform" {
  provider                  = azurerm.dev
  for_each                  = local.dev_networks
  name                      = "peer-${each.key}-to-hub"
  resource_group_name       = data.azurerm_resource_group.dev[each.value.resource_group_key].name
  virtual_network_name      = azurerm_virtual_network.dev[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.platform["hub"].id
  allow_forwarded_traffic   = true
}
