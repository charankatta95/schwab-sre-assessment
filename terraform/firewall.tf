resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.main.id
  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  source_ranges = ["10.10.0.0/20", "10.20.0.0/14", "10.30.0.0/20"]
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-gclb-health-checks"
  network = google_compute_network.main.id
  allow { protocol = "tcp" }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}
