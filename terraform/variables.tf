locals {
  data_lake_bucket = "data_lake"
  local_cloud_function_path = "../GCP/cloud_function.zip"
  credentials = jsondecode(file(var.credentials))
  service_account_email = local.credentials.client_email
  pubsub_topic = "event_file"
}

variable "project" {
  description = "Your GCP Project ID"
  type        = string
}

variable "region" {
  description = "Your project region"
  default     = "europe-west6"
  type        = string
}

variable "zone" {
  description = "Your project zone"
  default     = "europe-west6-a"
  type        = string
}

variable "credentials" {
  description = "Your google credentials"
  type        = string
}

variable "storage_class" {
  description = "Storage class type for your bucket"
  default     = "STANDARD"
  type        = string
}