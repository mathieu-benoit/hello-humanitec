variable "credentials" {
  description = "The credentials for connecting to Azure."
  type = object({
    project_id         = string
  })
  sensitive = true
}

variable "spanner_instance" {
  description = "ID of the Google Cloud Spanner Instance that the Service Account should have access"
  type        = string
}

variable "spanner_database" {
  description = "ID of the Google Cloud Spanner Database that the Service Account should have access"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace where the workload is"
  type        = string
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account used by the workload"
  type        = string
}