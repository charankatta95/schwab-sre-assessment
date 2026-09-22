resource "google_container_cluster" "primary" {
  name             = "schwab-cluster"
  location         = var.region
  enable_autopilot = true
  network          = google_compute_network.main.id
  subnetwork       = google_compute_subnetwork.gke.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  # so `terraform destroy` at teardown time isn't blocked
  deletion_protection = false
}
