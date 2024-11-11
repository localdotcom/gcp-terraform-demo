output "service_account_email" {
  value = google_service_account.private_gcs_sa.email
}

output "hmac_key" {
  value     = google_storage_hmac_key.private_gcs_hmac_key
  sensitive = true
}
