output "host" {
  value = azurerm_mysql_flexible_server.server.fqdn
}

output "name" {
  value = azurerm_mysql_flexible_database.database.name
}

output "port" {
  value = 3306
}

output "password" {
  value = azurerm_mysql_flexible_server.server.administrator_password
  sensitive = true
}

output "username" {
  value = azurerm_mysql_flexible_server.server.administrator_login
  sensitive = true
}