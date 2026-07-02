locals {
  env_config_all = {
    for row in csvdecode(file("${path.module}/csv/env_config.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  env_config = local.env_config_all["default"]

  tags = {
    Environment = local.env_config.environment
    Purpose     = local.env_config.purpose
    Owner       = local.env_config.owner
    CostCenter  = local.env_config.cost_center
    ExpiryDate  = local.env_config.expiry_date
  }

  resource_groups_all = {
    for row in csvdecode(file("${path.module}/csv/resource_groups.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  department_environments_all = {
    for row in csvdecode(file("${path.module}/csv/department_environments.csv")) :
    row.key => row
    if lower(row.create) == "true"
  }

  platform_resource_groups = {
    for key, row in local.resource_groups_all : key => row
    if row.subscription_key == "platform"
  }

  dev_resource_groups = {
    for key, row in local.resource_groups_all : key => row
    if row.subscription_key == "dev"
  }

  dev_department_environments = {
    for key, row in local.department_environments_all : key => row
    if row.subscription_key == "dev"
  }
}
