data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "workload" {
  for_each = local.resource_groups_all
  name     = each.value.name
}

data "azurerm_subnet" "workload" {
  for_each = local.subnet_refs_all

  name                 = each.value.name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = data.azurerm_resource_group.workload[each.value.resource_group_key].name
}
