terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.78.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "google" {
  project = var.credentials.project_id
}