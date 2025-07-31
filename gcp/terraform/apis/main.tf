terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.31.0"
    }
  }
}

provider "google-beta" {
  region = var.region
  project = var.project
}

resource "google_project_service" "required_apis" {
 for_each = toset(var.api_list)
  project = var.project
  service = each.key
  disable_on_destroy = false
}