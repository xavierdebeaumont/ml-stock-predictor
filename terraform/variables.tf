locals {
  data_lake_bucket = "data_lake"
}

variable "project" {
  description = "Your GCP Project ID"
  type        = string
}

variable "region" {
  description = "Your project region"
  default     = "europe-west9"
  type        = string
}

variable "zone" {
  description = "Your project zone"
  default     = "europe-west9-a"
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