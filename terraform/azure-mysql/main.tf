resource "random_string" "server_name" {
  length  = 8
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "random_string" "database_name" {
  length  = 8
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "random_string" "login" {
  length  = 8
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "random_password" "password" {
  length           = 8
  lower            = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  numeric          = true
  override_special = "_"
  special          = true
  upper            = true
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mysql_flexible_server
resource "azurerm_mysql_flexible_server" "server" {
  location                     = var.mysql_server_location
  name                         = "mysqlserver-${random_string.server_name.result}"
  resource_group_name          = var.resource_group_name
  administrator_login          = random_string.login.result
  administrator_password       = random_password.password.result
  sku_name                     = "Standard_B1ms"
  version                      = "8.0.21"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mysql_flexible_database
resource "azurerm_mysql_flexible_database" "database" {
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
  name                = "mysqldatabase_${random_string.database_name.result}"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.server.name
}