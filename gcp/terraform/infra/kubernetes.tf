resource "google_service_account" "metaflow_kubernetes_control_plane_service_account" {
  provider = google-beta
  # TODO fix names (e.g. gsa would be nice)
  # gsa-metaflow-k8s-ctrl-<workspace>
  account_id   = "sa-mf-k8s-${terraform.workspace}"
  display_name = "Service Account for Kubernetes Control Plane (${terraform.workspace})"
}

resource "google_project_iam_member" "control_plane_can_pull_from_artifact_registry" {
  provider = google-beta
  project  = var.project
  role     = "roles/artifactregistry.reader"
  member   = "serviceAccount:${google_service_account.metaflow_kubernetes_control_plane_service_account.email}"
  depends_on = [google_artifact_registry_repository.metaflow_docker_repo]
}

resource "google_project_organization_policy" "allow_external_ip" {
  project = var.project
  constraint = "constraints/compute.vmExternalIpAccess"
  boolean_policy {
    enforced = false
  }
}

resource "google_container_cluster" "metaflow_kubernetes" {
  provider = google-beta
  name               = var.kubernetes_cluster_name
  initial_node_count = 1
  location = var.gke_zone
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  lifecycle {
    ignore_changes = [
      node_config[0].kubelet_config,
      node_config[0].resource_labels
    ]
  }

  node_config {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.metaflow_kubernetes_control_plane_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum = 0
      maximum = 200
    }
    resource_limits {
      resource_type = "memory"
      minimum = 0
      maximum = 400
    }
  }
  network = google_compute_network.metaflow_compute_network.name
  subnetwork = google_compute_subnetwork.metaflow_subnet_for_kubernetes.name
  networking_mode = "VPC_NATIVE"
  # empty block is required
  ip_allocation_policy {}
}

resource "google_container_node_pool" "gpu_pool" {
  provider   = google-beta
  name       = "gpu-pool"
  location   = var.gke_zone
  cluster    = google_container_cluster.metaflow_kubernetes.name
  initial_node_count = 1

  lifecycle {
    ignore_changes = [
      autoscaling[0].location_policy,
      node_config[0].kubelet_config,
      node_config[0].resource_labels
    ]
  }

  autoscaling {
    total_min_node_count = 0
    total_max_node_count = 5
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    service_account = google_service_account.metaflow_kubernetes_control_plane_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }
    guest_accelerator {
      type  = var.gpu_type
      count = 1
    }
    image_type   = "COS_CONTAINERD"
    machine_type = var.gpu_machine_type 
    disk_size_gb = 100
    disk_type    = "pd-standard"
  }
}