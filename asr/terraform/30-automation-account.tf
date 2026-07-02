resource "azurerm_automation_account" "dr" {
  name                = var.automation_account_name
  location            = azurerm_resource_group.asr.location
  resource_group_name = azurerm_resource_group.asr.name
  sku_name            = "Basic"
  tags                = local.tags
}

# Note:
# ASR replicated VM, network mapping, protection container mapping, and recovery plan
# can be configured by Terraform provider resources or by the Azure CLI scripts under ../scripts.
# In many enterprise environments the CLI/PowerShell path is easier to control because ASR
# object names are generated from fabric/protection-container discovery results.
