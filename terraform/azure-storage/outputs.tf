output "container" {
  value = azurerm_storage_container.storage_container.name
}

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}