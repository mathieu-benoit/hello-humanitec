output "container" {
  value = azurerm_storage_container.storage_container.name
}

output "account" {
  value = azurerm_storage_account.storage_account.name
}
