locals {
  private_gcs                = data.terraform_remote_state.gcs.outputs.private_gcs
  hmac_key_access_ids        = { for k, v in data.terraform_remote_state.iam.outputs.hmac_key : k => v.access_id }
  hmac_key_secrets           = { for k, v in data.terraform_remote_state.iam.outputs.hmac_key : k => v.secret }
  backend_svc_ids            = { for k, v in google_compute_backend_service.private_gcs_backend_svc : k => v.id }
  private_gcs_neg_ids        = { for k, v in google_compute_global_network_endpoint_group.private_gcs_neg : k => v.id }
  private_gcs_ne_fqdns       = { for k, v in google_compute_global_network_endpoint.private_gcs_ne : k => v.fqdn }
  https_redirect_url_map_ids = { for k, v in google_compute_url_map.https_redirect_url_map : k => v.id }
  alb_url_map_ids            = { for k, v in google_compute_url_map.alb_url_map : k => v.id }
  global_address_ids         = { for k, v in google_compute_global_address.alb_global_address : k => v.id }
  global_address_addresses   = { for k, v in google_compute_global_address.alb_global_address : k => v.address }
  ssl_certificate_ids        = { for k, v in google_compute_managed_ssl_certificate.alb_managed_cert : k => v.id }
  target_http_proxy_ids      = { for k, v in google_compute_target_http_proxy.alb_http_target_proxy : k => v.id }
  target_https_proxy_ids     = { for k, v in google_compute_target_https_proxy.alb_https_target_proxy : k => v.id }
}
