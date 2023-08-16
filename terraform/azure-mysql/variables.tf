variable "credentials" {
  description = "The credentials for connecting to Azure."
  type = object({
    azure_subscription_id         = string
    azure_subscription_tenant_id  = string
    service_principal_id          = string
    service_principal_password    = string
  })
  sensitive = true
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to use"
  type        = string
}

variable "mysql_server_location" {
  description = "Location of Azure MySQL Server"
  type        = string
  default     = "eastus"
}