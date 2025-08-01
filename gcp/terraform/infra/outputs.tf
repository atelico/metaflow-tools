output metaflow_workload_identity_gsa_id {
  value = google_service_account.metaflow_kubernetes_workload_identity_service_account.id
}

output metaflow_kubernetes_gpu_tolerations {
  value = jsonencode([
    for taint in google_container_node_pool.gpu_pool.node_config[0].taint : {
      key      = taint.key
      operator = "Equal"
      value    = taint.value
      effect   = lower(replace(taint.effect, "_", ""))
    }
  ])
  }