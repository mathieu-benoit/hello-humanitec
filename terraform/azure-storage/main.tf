resource "random_string" "storage_account_name_sufix" {
  length  = 16
  special = false
  lower   = true
}

resource "random_string" "storage_container_name_sufix" {
  length  = 16
  special = false
  lower   = true
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
resource "azurerm_storage_account" "storage_account" {
  name                     = "storage${random_string.storage_account_name_sufix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.storage_account_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container
resource "azurerm_storage_container" "storage_container" {
  name                  = "storage${random_string.storage_container_name_sufix.result}"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}