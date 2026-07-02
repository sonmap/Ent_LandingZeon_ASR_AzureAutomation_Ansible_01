variable "subscription_id" { type = string }
variable "environment" { type = string default = "dr" }
variable "owner" { type = string default = "son" }

variable "primary_location" { type = string default = "koreacentral" }
variable "vault_location" { type = string default = "japaneast" }

variable "asr_resource_group_name" { type = string default = "rg-land03-asr-jpe" }
variable "recovery_services_vault_name" { type = string default = "rsv-land03-krc-to-jpe-001" }
variable "automation_account_name" { type = string default = "aa-land03-dr-runbook-jpe" }

variable "primary_cache_resource_group_name" { type = string default = "rg-land03-dev-workloads" }
variable "cache_storage_account_name" { type = string }
