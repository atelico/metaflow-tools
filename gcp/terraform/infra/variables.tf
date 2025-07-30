variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "gke_region" {
  type = string
}

variable "gke_zone" {
  type = string
}

variable "gpu_type" {
  type = string
}

variable "gpu_machine_type" {
  type = string
}

variable "gpu_driver_version" {
  type = string
}

variable "project" {
  type = string
}

variable "database_server_name" {
  type = string
}

variable "kubernetes_cluster_name" {
  type = string
}

variable "metaflow_workload_identity_gsa_name" {
  type = string
}

variable "storage_bucket_name" {
  type = string
}

variable "artifact_repo_name" {
  type = string
}

variable "service_account_key_file" {
  type = string
}