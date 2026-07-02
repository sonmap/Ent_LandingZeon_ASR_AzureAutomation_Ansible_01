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
