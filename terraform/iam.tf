resource "google_service_account" "ci_cd" {
  account_id   = "ci-cd-sa"
  display_name = "CI/CD service account"
}

resource "google_service_account" "sre" {
  account_id   = "sre-sa"
  display_name = "SRE service account"
}

resource "google_service_account" "ops" {
  account_id   = "ops-sa"
  display_name = "Ops service account"
}

resource "google_service_account" "dev" {
  account_id   = "dev-sa"
  display_name = "Dev service account"
}

resource "google_project_iam_member" "ci_cd_container_dev" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.ci_cd.email}"
}

resource "google_project_iam_member" "sre_monitoring_admin" {
  project = var.project_id
  role    = "roles/monitoring.admin"
  member  = "serviceAccount:${google_service_account.sre.email}"
}

resource "google_project_iam_member" "ops_logging_admin" {
  project = var.project_id
  role    = "roles/logging.admin"
  member  = "serviceAccount:${google_service_account.ops.email}"
}

resource "google_project_iam_member" "dev_cluster_viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = "serviceAccount:${google_service_account.dev.email}"
}
