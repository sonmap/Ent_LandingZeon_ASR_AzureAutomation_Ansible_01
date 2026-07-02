resource "azurerm_kubernetes_cluster" "aks" {
  for_each                = local.aks_clusters
  name                    = each.value.name
  location                = data.azurerm_resource_group.workload["dev"].location
  resource_group_name     = data.azurerm_resource_group.workload["dev"].name
  dns_prefix              = each.value.dns_prefix
  private_cluster_enabled = lower(each.value.private_cluster_enabled) == "true"
  private_dns_zone_id     = each.value.private_dns_zone_id
  sku_tier                = each.value.sku_tier
  tags                    = local.tags

  default_node_pool {
    name                        = each.value.node_pool_name
    vm_size                     = each.value.node_pool_vm_size
    node_count                  = tonumber(each.value.node_pool_count)
    vnet_subnet_id              = data.azurerm_subnet.workload[each.value.subnet_key].id
    temporary_name_for_rotation = each.value.node_pool_temporary_name
  }

  identity {
    type = each.value.identity_type
  }

  network_profile {
    network_plugin    = each.value.network_plugin
    load_balancer_sku = each.value.load_balancer_sku
    outbound_type     = each.value.outbound_type
  }
}

resource "random_string" "suffix" {
  length  = tonumber(local.app_config.random_suffix_length)
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_storage_account" "ai" {
  for_each                        = local.ai_services
  name                            = "${each.value.storage_name_prefix}${random_string.suffix.result}"
  location                        = data.azurerm_resource_group.workload["dev"].location
  resource_group_name             = data.azurerm_resource_group.workload["dev"].name
  account_tier                    = each.value.storage_tier
  account_replication_type        = each.value.storage_replication_type
  public_network_access_enabled   = lower(each.value.storage_public_network_access) == "true"
  allow_nested_items_to_be_public = lower(each.value.storage_allow_nested_items_public) == "true"
  tags                            = local.tags
}

resource "azurerm_key_vault" "ai" {
  for_each                      = local.ai_services
  name                          = "${each.value.key_vault_name_prefix}-${random_string.suffix.result}"
  location                      = data.azurerm_resource_group.workload["dev"].location
  resource_group_name           = data.azurerm_resource_group.workload["dev"].name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = each.value.key_vault_sku
  public_network_access_enabled = lower(each.value.key_vault_public_network_access) == "true"
  purge_protection_enabled      = lower(each.value.key_vault_purge_protection) == "true"
  soft_delete_retention_days    = tonumber(each.value.key_vault_soft_delete_days)
  tags                          = local.tags
}

resource "azurerm_private_endpoint" "storage_blob" {
  for_each            = local.ai_services
  name                = each.value.private_endpoint_name
  location            = data.azurerm_resource_group.workload["dev"].location
  resource_group_name = data.azurerm_resource_group.workload["dev"].name
  subnet_id           = data.azurerm_subnet.workload[each.value.private_endpoint_subnet_key].id
  tags                = local.tags

  private_service_connection {
    name                           = each.value.private_service_connection_name
    private_connection_resource_id = azurerm_storage_account.ai[each.key].id
    subresource_names              = [each.value.private_endpoint_subresource]
    is_manual_connection           = false
  }
}
