#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

log "Post failover network check started"
require_env TARGET_RG
require_env TARGET_VNET
require_env TARGET_SUBNET
require_env PRIVATE_DNS_RG
az_login_check

log "VNet summary"
az network vnet show -g "$TARGET_RG" -n "$TARGET_VNET" --query "{name:name,location:location,addressSpace:addressSpace.addressPrefixes}" -o json

log "Subnet summary"
az network vnet subnet show -g "$TARGET_RG" --vnet-name "$TARGET_VNET" -n "$TARGET_SUBNET" --query "{name:name,addressPrefix:addressPrefix,addressPrefixes:addressPrefixes,routeTable:routeTable.id,networkSecurityGroup:networkSecurityGroup.id}" -o json

log "NIC list"
az network nic list -g "$TARGET_RG" --query "[].{name:name,privateIp:ipConfigurations[0].privateIPAddress,subnet:ipConfigurations[0].subnet.id,nsg:networkSecurityGroup.id}" -o table

log "NSG list"
az network nsg list -g "$TARGET_RG" --query "[].{name:name,location:location}" -o table || true

log "Route table list"
az network route-table list -g "$TARGET_RG" --query "[].{name:name,location:location}" -o table || true

log "Private DNS zones"
az network private-dns zone list -g "$PRIVATE_DNS_RG" --query "[].{name:name,resourceGroup:resourceGroup}" -o table || true

log "Post failover network check completed"
