terraform {
  backend "gcs" {
    bucket = "pl-data-tf-state"
    prefix = "filcryo/prod"
  }
}

provider "google" {
  project = "protocol-labs-data"
  region  = "eu-west1"
}


resource "google_service_account" "filcryo" {
  account_id   = "filcryo-service-account"
  display_name = "Filcryo"
}

resource "google_project_iam_custom_role" "filcryo_bucket_role" {
  role_id     = "filcryo_bucket_role"
  title       = "Filcryo Bucket permissions"
  description = "Bucket-specific permissions for Filcryo"
  permissions = [
    "orgpolicy.policy.get",
    "resourcemanager.projects.get",
    "storage.multipartUploads.abort",
    "storage.multipartUploads.create",
    "storage.multipartUploads.list",
    "storage.multipartUploads.listParts",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.getIamPolicy",
    "storage.objects.setIamPolicy",
    "storage.objects.list",
    "storage.objects.update",
    "storage.buckets.list",
    "storage.buckets.get",
  ]
}

resource "google_project_iam_custom_role" "filcryo_project_role" {
  role_id     = "filcryo_project_role"
  title       = "Filcryo Project permissions"
  description = "Project-wide permissions for Filcryo"
  permissions = [
    "storage.buckets.list",
    "serviceusage.services.use",
  ]
}

resource "google_storage_bucket_iam_member" "filcryo" {
  bucket = "fil-mainnet-archival-snapshots"
  role   = google_project_iam_custom_role.filcryo_bucket_role.name
  member = "serviceAccount:${google_service_account.filcryo.email}"
}

resource "google_project_iam_member" "filcryo" {
  project = "protocol-labs-data"
  role    = google_project_iam_custom_role.filcryo_project_role.name
  member  = "serviceAccount:${google_service_account.filcryo.email}"
}

locals {
  secrets = {
    secret1 = "FILCRYO_PROMETHEUS_USERNAME",
    secret2 = "FILCRYO_PROMETHEUS_PASSWORD",
    secret3 = "FILCRYO_LOKI_USERNAME",
    secret4 = "FILCRYO_LOKI_PASSWORD",
  }
}

resource "google_secret_manager_secret_iam_binding" "secret_access" {
  for_each = local.secrets

  project   = "protocol-labs-data"
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${google_service_account.filcryo.email}",
  ]
}

resource "google_compute_instance" "filcryo" {
  name                      = "filcryo"
  machine_type              = "n2d-standard-16"
  zone                      = "europe-west1-b"
  tags                      = ["filcryo"]
  allow_stopping_for_update = false

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email = google_service_account.filcryo.email
    scopes = [
      "storage-rw",
      "cloud-platform",
    ]
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = "2048"
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"

    access_config {
      # Give machine a public IP
    }
  }

  metadata = {
    project = "filcryo"
    team    = "sentinel"
  }

  # Run script on boot
  metadata_startup_script = file("boot.sh")
}



resource "google_compute_firewall" "allow-ssh" {
  name      = "allow-ssh"
  network   = "default"
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["filcryo"]
}

output "instance_public_ip" {
  value = google_compute_instance.filcryo.network_interface[0].access_config[0].nat_ip
}

output "service_account" {
  value = google_service_account.filcryo.email
}
