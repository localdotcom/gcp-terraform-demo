# create a bucket
resource "google_storage_bucket" "private_gcs" {
  for_each = toset(var.gcs.buckets)

  name                        = "${var.project}-${each.value}"
  location                    = var.gcs.location
  storage_class               = var.gcs.storage_class
  public_access_prevention    = var.gcs.public_access_prevention
  uniform_bucket_level_access = var.gcs.uniform_bucket_level_access

  versioning {
    enabled = var.gcs.versioning.enabled
  }

  force_destroy = true
}