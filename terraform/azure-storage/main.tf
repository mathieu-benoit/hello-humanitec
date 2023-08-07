resource "random_string" "storage_account_name_sufix" {
  length  = 16
  special = false
}

resource "random_string" "storage_container_name_sufix" {
  length  = 16
  special = false
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "storage${lower(random_string.storage_account_name_sufix.result)}"
  resource_group_name      = var.resource_group_name
  location                 = var.storage_account_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storage_container" {
  name                  = "storage${lower(random_string.storage_container_name_sufix.result)}"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}