output "platform_vnet_ids" {
  value = { for key, vnet in azurerm_virtual_network.platform : key => vnet.id }
}

output "dev_vnet_ids" {
  value = { for key, vnet in azurerm_virtual_network.dev : key => vnet.id }
}

output "private_dns_zone_ids" {
  value = { for key, zone in azurerm_private_dns_zone.zones : key => zone.id }
}
