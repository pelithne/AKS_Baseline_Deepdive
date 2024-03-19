output "primary_access_key" {
  description = "The storage account primary access key"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.storage.id
}
