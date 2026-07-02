output "vm_private_ips" {
  value = { for key, nic in azurerm_network_interface.vm : key => nic.private_ip_address }
}

output "aks_private_fqdn" {
  value = { for key, aks in azurerm_kubernetes_cluster.aks : key => aks.private_fqdn }
}

output "storage_account_names" {
  value = { for key, account in azurerm_storage_account.ai : key => account.name }
}

output "key_vault_ids" {
  value = { for key, vault in azurerm_key_vault.ai : key => vault.id }
}
