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
  project = var.project
  region  = var.region
  zone    = var.zone
  credentials = file(var.credentials)  # Use this if you do not want to set env-var GOOGLE_APPLICATION_CREDENTIALS
}

resource "google_storage_bucket" "bucket" {
    name = "${local.data_lake_bucket}_${var.project}"
    location = var.region
    force_destroy = true

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

resource "google_cloudfunctions_function" "stock_data_function" {
  name        = "stock-data-function"
  description = "Cloud Function to retrieve and ingest stock data"
  runtime     = "python310"
  entry_point = "load_data"
  source_archive_bucket = "${local.data_lake_bucket}_${var.project}"
  source_archive_object = var.local_cloud_function_path
  
  environment_variables = {
    "BUCKET_NAME" = "${local.data_lake_bucket}_${var.project}"
  }

  trigger_http = true
}

resource "google_cloud_scheduler_job" "scheduler_job" {
  name        = "daily-scheduler-job"
  description = "Daily Cloud Function Trigger"
  schedule    = "0 0 * * *"
  time_zone   = "UTC"
  http_target {
    uri = google_cloudfunctions_function.stock_data_function.https_trigger_url
    http_method = "POST"
  }
}