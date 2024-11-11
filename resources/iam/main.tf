# create a service account
resource "google_service_account" "private_gcs_sa" {
  project      = var.project
  account_id   = var.iam.service_account.name
  display_name = var.iam.service_account.display_name
}

resource "google_storage_bucket_iam_member" "private_gcs_member" {
  for_each = local.private_gcs

  bucket = each.value.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.private_gcs_sa.email}"

  depends_on = [google_service_account.private_gcs_sa]
}

# create a hmac key
resource "google_storage_hmac_key" "private_gcs_hmac_key" {
  for_each = local.private_gcs

  project               = var.project
  service_account_email = google_service_account.private_gcs_sa.email
}
