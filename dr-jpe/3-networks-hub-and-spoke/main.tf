locals {
  network_config_all = {
    for row in csvdecode(file("${path.module}/csv/network_config.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  network_config = local.network_config_all["default"]

  tags = {
    Environment = local.network_config.environment
    Purpose     = local.network_config.purpose
    Owner       = local.network_config.owner
    CostCenter  = local.network_config.cost_center
    ExpiryDate  = local.network_config.expiry_date
  }

  resource_groups_all = {
    for row in csvdecode(file("${path.module}/csv/resource_groups.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  networks_all = {
    for row in csvdecode(file("${path.module}/csv/networks.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  subnets_all = {
    for row in csvdecode(file("${path.module}/csv/subnets.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  routes_all = {
    for row in csvdecode(file("${path.module}/csv/routes.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  private_dns_zones_all = {
    for row in csvdecode(file("${path.module}/csv/private_dns_zones.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  platform_networks = { for key, row in local.networks_all : key => row if row.subscription_key == "platform" }
  dev_networks      = { for key, row in local.networks_all : key => row if row.subscription_key == "dev" }
  platform_subnets  = { for key, row in local.subnets_all : key => row if row.subscription_key == "platform" }
  dev_subnets       = { for key, row in local.subnets_all : key => row if row.subscription_key == "dev" }
  dev_routes        = { for key, row in local.routes_all : key => row if row.subscription_key == "dev" }
}

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
