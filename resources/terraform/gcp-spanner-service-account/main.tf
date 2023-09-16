# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account
resource "google_service_account" "spanner_access" {
  account_id    = "spanner-${var.kubernetes_namespace}-${var.kubernetes_service_account}"
  description   = "Account used to access the Spanner Database"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_database_iam
resource "google_spanner_database_iam_member" "spanner_access" {
  instance = var.spanner_instance
  database = var.spanner_database
  role     = "roles/spanner.databaseUser"
  member   = "serviceAccount:${google_service_account.spanner_access.email}"
}

# 
resource "google_service_account_iam_binding" "spanner_access" {
  service_account_id = google_service_account.spanner_access.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.credentials.project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.kubernetes_service_account}]",
  ]
}