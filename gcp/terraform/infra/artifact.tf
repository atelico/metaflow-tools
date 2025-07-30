resource "google_artifact_registry_repository" "metaflow_docker_repo" {
  provider = google-beta
  location      = var.region                      
  repository_id = var.artifact_repo_name
  format        = "DOCKER"
  description = "Docker image repository for Metaflow"
}