locals {
  app_config_all = {
    for row in csvdecode(file("${path.module}/csv/app_config.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  app_config = local.app_config_all["default"]

  tags = {
    Environment = local.app_config.environment
    Purpose     = local.app_config.purpose
    Owner       = local.app_config.owner
    CostCenter  = local.app_config.cost_center
    ExpiryDate  = local.app_config.expiry_date
  }

  resource_groups_all = {
    for row in csvdecode(file("${path.module}/csv/resource_groups.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  subnet_refs_all = {
    for row in csvdecode(file("${path.module}/csv/subnet_refs.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  vm_workloads = {
    for row in csvdecode(file("${path.module}/csv/vm_workloads.csv")) :
    row.key => row
    if lower(row.create) == "true" && lower(local.app_config.enable_vm) == "true"
  }

  aks_clusters = {
    for row in csvdecode(file("${path.module}/csv/aks_clusters.csv")) :
    row.key => row
    if lower(row.create) == "true" && lower(local.app_config.enable_aks) == "true"
  }

  ai_services = {
    for row in csvdecode(file("${path.module}/csv/ai_services.csv")) :
    row.key => row
    if lower(row.create) == "true" && lower(local.app_config.enable_ai_foundry) == "true"
  }
}
