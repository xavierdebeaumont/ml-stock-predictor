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

resource "google_cloud_scheduler_job" "my_scheduler_job" {
  name        = "my-scheduler-job"
  description = "Daily Cloud Function Trigger"
  schedule    = "0 0 * * *"
  time_zone   = "UTC"
  target      = google_cloudfunctions_function.my_function.name

  pubsub_target {
    topic_name = "projects/your-project-id/topics/my-topic"
    data       = ""
  }
}

resource "google_cloudfunctions_function" "my_function" {
  name        = "my-function"
  description = "My Cloud Function"
  runtime     = "python310"

  source_repository {
    url = "https://github.com/your-repo/my-function"
  }

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/your-project-id/topics/my-topic"
  }

  available_memory_mb = 128
  timeout             = "60s"

  environment_variables = {
    VAR_NAME = "value"
  }
}