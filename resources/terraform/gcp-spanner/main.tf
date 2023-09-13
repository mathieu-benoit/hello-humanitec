resource "random_string" "spanner_instance_name" {
  length  = 10
  special = false
  lower   = true
  upper   = false
}

resource "random_string" "spanner_database_name" {
  length  = 10
  special = false
  lower   = true
  upper   = false
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_instance
resource "google_spanner_instance" "instance" {
  name      = spanner_instance_name.result
  config    = "regional-europe-west1"
  num_nodes = 1
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/spanner_database
resource "google_spanner_database" "database" {
  instance          = google_spanner_instance.instance.name
  name              = spanner_database_name.result
  database_dialect  = "GOOGLE_STANDARD_SQL"
  ddl               = [
    "CREATE TABLE CartItems (userId STRING(1024), productId STRING(1024), quantity INT64) PRIMARY KEY (userId, productId)",
    "CREATE INDEX CartItemsByUserId ON CartItems(userId)"
  ]
}