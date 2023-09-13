variable "credentials" {
  description = "The credentials for connecting to Azure."
  type = object({
    project_id         = string
  })
  sensitive = true
}

variable "spanner_instance_config" {
  description = "The Spanner Instance config/location"
  type        = string
  default     = "regional-us-east5"
}

variable "spanner_instance_num_nodes" {
  description = "The Spanner Instance number of nodes"
  type        = integer
  default     = 1
}

variable "spanner_database_dialect" {
  description = "The Spanner Database dialect"
  type        = string
  default     = "GOOGLE_STANDARD_SQL"
}