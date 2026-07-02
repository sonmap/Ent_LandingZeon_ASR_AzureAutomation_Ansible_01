resource "azurerm_resource_group" "department_dev" {
  provider = azurerm.dev
  for_each = local.dev_department_environments

  name     = each.value.resource_group_name
  location = each.value.location
  tags = merge(local.tags, {
    Department         = each.value.department
    Environment        = each.value.environment
    DataClassification = each.value.data_classification
    ApprovalRequired   = each.value.approval_required
    NetworkSpoke       = each.value.network_spoke_key
    Purpose            = "${each.value.department}-${each.value.environment}-workload-boundary"
  })
}
