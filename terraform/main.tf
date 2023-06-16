terraform {
  required_version = ">=1.0"
  backend "local" {}
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project      = var.project
  region       = var.region
  zone         = var.zone
  credentials  = file(var.credentials)
}

resource "google_storage_bucket" "bucket" {
  name                  = "${local.data_lake_bucket}_${var.project}"
  location              = var.region
  force_destroy         = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30 # days
    }
  }
}

resource "google_storage_bucket_object" "cloud_function_zip" {
  name   = "cloud_function.zip"
  bucket = google_storage_bucket.bucket.name
  source = local.local_cloud_function_path

  depends_on = [google_storage_bucket.bucket]
}

resource "google_cloudfunctions_function" "stock_data_function" {
  name        = "stock-data-function"
  description = "Cloud Function to retrieve and ingest stock data"
  runtime     = "python310"
  entry_point = "load_data"
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.cloud_function_zip.name

  environment_variables = {
    "BUCKET_NAME" = google_storage_bucket.bucket.name
  }

  trigger_http = true

  depends_on = [google_storage_bucket_object.cloud_function_zip]
}

resource "google_cloud_scheduler_job" "scheduler_job" {
  name        = "daily-scheduler-job"
  description = "Daily Cloud Function Trigger"
  schedule    = "0 0 * * *"
  time_zone   = "UTC"

  http_target {
    uri          = google_cloudfunctions_function.stock_data_function.https_trigger_url
    http_method  = "POST"

    oidc_token {
      service_account_email = local.service_account_email
    }
  }

  depends_on = [google_cloudfunctions_function.stock_data_function]
}
