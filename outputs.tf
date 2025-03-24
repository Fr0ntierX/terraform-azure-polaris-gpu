output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_machine_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "virtual_machine_public_ip" {
  description = "Public IP address of the virtual machine"
  value       = azurerm_public_ip.main.ip_address
}

output "virtual_machine_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.id
}

output "key_vault_name" {
  description = "Name of the key vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the key vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_name" {
  description = "Name of the key"
  value       = local.key_name
}

output "polaris_proxy_endpoint" {
  description = "Endpoint for Polaris proxy"
  value       = "http://${azurerm_public_ip.main.ip_address}:${var.polaris_proxy_port}"
}