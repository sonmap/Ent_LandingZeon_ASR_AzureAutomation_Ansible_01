resource "azurerm_network_interface" "vm" {
  for_each            = local.vm_workloads
  name                = each.value.nic_name
  location            = data.azurerm_resource_group.workload["dev"].location
  resource_group_name = data.azurerm_resource_group.workload["dev"].name
  tags                = local.tags

  ip_configuration {
    name                          = each.value.ip_configuration_name
    subnet_id                     = data.azurerm_subnet.workload[each.value.subnet_key].id
    private_ip_address_allocation = each.value.private_ip_allocation
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each                        = local.vm_workloads
  name                            = each.value.vm_name
  location                        = data.azurerm_resource_group.workload["dev"].location
  resource_group_name             = data.azurerm_resource_group.workload["dev"].name
  size                            = each.value.vm_size
  admin_username                  = local.app_config.vm_admin_username
  admin_password                  = local.app_config.vm_admin_password
  disable_password_authentication = lower(each.value.disable_password_authentication) == "true"
  network_interface_ids           = [azurerm_network_interface.vm[each.key].id]
  tags                            = local.tags

  os_disk {
    caching              = each.value.os_disk_caching
    storage_account_type = each.value.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = each.value.image_publisher
    offer     = each.value.image_offer
    sku       = each.value.image_sku
    version   = each.value.image_version
  }
}
