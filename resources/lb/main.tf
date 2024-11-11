# create a global network endpoint group
resource "google_compute_global_network_endpoint_group" "private_gcs_neg" {
  for_each = local.private_gcs

  name                  = "${each.value.name}-neg"
  project               = var.project
  network_endpoint_type = "INTERNET_FQDN_PORT"
  default_port          = 443
}

# create a global network endpoint
resource "google_compute_global_network_endpoint" "private_gcs_ne" {
  for_each = local.private_gcs

  global_network_endpoint_group = local.private_gcs_neg_ids[each.key]
  fqdn                          = "${each.value.name}.storage.googleapis.com"
  port                          = 443
}

# create a backend service
resource "google_compute_backend_service" "private_gcs_backend_svc" {
  for_each = local.private_gcs

  project               = var.project
  name                  = "${each.value.name}-backend-svc"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  enable_cdn            = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    client_ttl                   = 7200
    max_ttl                      = 10800
    negative_caching             = true
    signed_url_cache_max_age_sec = 7200
  }

  custom_request_headers = [
    "host: ${local.private_gcs_ne_fqdns[each.key]}"
  ]

  backend {
    group = local.private_gcs_neg_ids[each.key]
  }

  security_settings {
    aws_v4_authentication {
      access_key_id      = local.hmac_key_access_ids[each.key]
      access_key         = local.hmac_key_secrets[each.key]
      access_key_version = "latest"
      origin_region      = var.region
    }
  }
}

# create a https redirect url_map
resource "google_compute_url_map" "https_redirect_url_map" {
  for_each = local.private_gcs

  project = var.project
  name    = "${each.value.name}-https-redirect-url-map"

  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

# create an ALB url_map
resource "google_compute_url_map" "alb_url_map" {
  for_each = local.private_gcs

  provider        = google-beta
  project         = var.project
  name            = "${each.value.name}-alb-url-map"
  default_service = local.backend_svc_ids[each.key]

  host_rule {
    hosts        = ["${each.value.name}.site"]
    path_matcher = "default-matcher"
  }

  path_matcher {
    name            = "default-matcher"
    default_service = local.backend_svc_ids[each.key]

    # serve error codes
    default_custom_error_response_policy {
      error_response_rule {
        match_response_codes   = ["4xx"]
        path                   = "/error.html"
        override_response_code = 404
      }
      error_service = local.backend_svc_ids[each.key]
    }

    path_rule {
      paths   = ["/"]
      service = local.backend_svc_ids[each.key]

      # rewrite '/' to '/index.html'
      route_action {
        url_rewrite {
          host_rewrite        = "${each.value.name}.site"
          path_prefix_rewrite = "/index.html"
        }
      }
    }
  }

  header_action {
    request_headers_to_remove = ["Cookie"]
  }
}

# create a target http proxy
resource "google_compute_target_http_proxy" "alb_http_target_proxy" {
  for_each = local.private_gcs

  project = var.project
  name    = "${each.value.name}-alb-http-target-proxy"
  url_map = local.https_redirect_url_map_ids[each.key]

}

# create a target https proxy
resource "google_compute_target_https_proxy" "alb_https_target_proxy" {
  for_each = local.private_gcs

  project          = var.project
  name             = "${each.value.name}-alb-https-target-proxy"
  url_map          = local.alb_url_map_ids[each.key]
  ssl_certificates = [local.ssl_certificate_ids[each.key]]
}

# create a global forwarding rule http
resource "google_compute_global_forwarding_rule" "alb_forwarding_rule_http" {
  for_each = local.private_gcs

  project               = var.project
  name                  = "${each.value.name}-alb-forwarding-rule-http"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = local.target_http_proxy_ids[each.key]
  ip_address            = local.global_address_ids[each.key]
}

# create a global forwarding rule https
resource "google_compute_global_forwarding_rule" "alb_forwarding_rule_https" {
  for_each = local.private_gcs

  project               = var.project
  name                  = "${each.value.name}-alb-forwarding-rule-https"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = local.target_https_proxy_ids[each.key]
  ip_address            = local.global_address_ids[each.key]
}

# create a global IP address
resource "google_compute_global_address" "alb_global_address" {
  for_each = local.private_gcs

  project      = var.project
  name         = "${each.value.name}-alb-global-adress"
  address_type = "EXTERNAL"
}

# create a managed ssl certificate
resource "google_compute_managed_ssl_certificate" "alb_managed_cert" {
  for_each = local.private_gcs

  project = var.project
  name    = "${each.value.name}-managed-alb-certs"

  managed {
    domains = ["${each.value.name}.site"]
  }
}

# create a DNS zone
resource "google_dns_managed_zone" "domain_managed_zone" {
  for_each = local.private_gcs

  name     = each.value.name
  dns_name = "${each.value.name}.site."

  force_destroy = "true"
}

# register a global IP address in DNS zone
resource "google_dns_record_set" "lb_a_record" {
  for_each = google_dns_managed_zone.domain_managed_zone

  project      = var.project
  name         = each.value.dns_name
  managed_zone = each.value.name
  type         = "A"
  ttl          = 300
  rrdatas      = [local.global_address_addresses[each.key]]
}













# # resource "google_compute_url_map" "https_redirect_url_map" {
# #   project = var.project_id
# #   name    = "${var.prefix}-https-redirect-url-map"

# #   default_url_redirect {
# #     https_redirect         = true
# #     strip_query            = false
# #     redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
# #   }
# # }

# resource "google_compute_url_map" "alb_url_map" {
#   project         = var.project
#   name            = "${local.private_gcs.name}-url-map"
#   default_service = google_compute_backend_bucket.private_gcs_backend.id
#   # default_service = element(values(local.backend_bucket_ids), 0)

#   dynamic "host_rule" {
#     # for_each = google_compute_backend_bucket.private_gcs_backends
#     for_each = local.asset_folders

#     content {
#       hosts = [host_rule.value.name]
#       # hosts = ["${host_rule.value.name}"]
#       # path_matcher = "${host_rule.value.name}-path-matcher"
#       path_matcher = replace("${host_rule.value.name}-path-matcher", ".", "-")
#     }
#   }

#   dynamic "path_matcher" {
#     for_each = local.asset_folders
#     # for_each = google_compute_backend_bucket.private_gcs_backends

#     content {
#       name                = replace("${path_matcher.value.name}-path-matcher", ".", "-")
#       default_service = google_compute_backend_bucket.private_gcs_backend.id

#       dynamic "path_rule" {
#         for_each = ["/${path_matcher.value.name}/*"]

#         content {
#           paths   = [path_rule.value]
#           service = google_compute_backend_bucket.private_gcs_backend.id
#         }
#       }
#     }
#   }

#   header_action {
#     request_headers_to_remove = ["Cookie"]
#   }
# }

# resource "google_compute_target_https_proxy" "alb_https_target_proxy" {
#   project          = var.project
#   name             = "${local.private_gcs.name}-alb-https-target-proxy"
#   url_map          = google_compute_url_map.alb_url_map.id
#   ssl_certificates = [google_compute_managed_ssl_certificate.alb_managed_cert.id]
# }

# resource "google_compute_global_forwarding_rule" "alb_forwarding_rule_https" {
#   project               = var.project
#   name                  = "${local.private_gcs.name}-alb-forwarding-rule-https"
#   ip_protocol           = "TCP"
#   load_balancing_scheme = "EXTERNAL_MANAGED"
#   port_range            = "443"
#   target                = google_compute_target_https_proxy.alb_https_target_proxy.id
#   ip_address            = google_compute_global_address.alb_global_address.id
# }

# resource "google_compute_global_address" "alb_global_address" {
#   project      = var.project
#   name         = "${local.private_gcs.name}-alb-global-adress"
#   address_type = "EXTERNAL"
# }

# resource "google_compute_managed_ssl_certificate" "alb_managed_cert" {
#   project = var.project
#   name    = "${local.private_gcs.name}-managed-alb-certs"

#   managed {
#     domains = [for k, v in local.asset_folders : v.name]
#   }
# }

# # create a DNS zone
# resource "google_dns_managed_zone" "domain_managed_zone" {
#   for_each = local.asset_folders

#   name          = regex("^([^\\.]+)", each.value.name)[0]
#   dns_name      = "${each.value.name}."
#   # description   = "Public DNS zone"

#   force_destroy = "true"
# }

# # register  ip address in DNS
# resource "google_dns_record_set" "lb_a_record" {
#   for_each = google_dns_managed_zone.domain_managed_zone

#   project = var.project
#   name = each.value.dns_name
#   managed_zone = each.value.name
#   type = "A"
#   ttl = 300
#   rrdatas = [google_compute_global_address.alb_global_address.address]
# }

# # # create a global network endpoint group
# # resource "google_compute_global_network_endpoint_group" "private_gcs_neg" {
# #   name                  = "${local.private_gcs.name}-neg"
# #   project               = var.project
# #   network_endpoint_type = "INTERNET_FQDN_PORT"
# #   default_port          = 443
# # }

# # # create a global network endpoint
# # resource "google_compute_global_network_endpoint" "private_gcs_ne" {
# #   global_network_endpoint_group = google_compute_global_network_endpoint_group.private_gcs_neg.id
# #   fqdn                          = "${local.private_gcs.name}.storage.googleapis.com"
# #   port                          = 443
# # }

# # resource "google_compute_backend_service" "private_gcs_backend_svc" {
# #   project               = var.project
# #   name                  = "${local.private_gcs.name}-backend-svc"
# #   load_balancing_scheme = "EXTERNAL_MANAGED"
# #   protocol              = "HTTPS"
# #   enable_cdn            = true

# #   custom_request_headers = [
# #     "host: ${google_compute_global_network_endpoint.private_gcs_ne.fqdn}"
# #   ]

# #   backend {
# #     group = google_compute_global_network_endpoint_group.private_gcs_neg.id
# #   }

# #   security_settings {
# #     aws_v4_authentication {
# #       access_key_id      = local.hmac_key.access_id
# #       access_key         = local.hmac_key.secret
# #       access_key_version = "latest"
# #       origin_region      = var.region
# #     }
# #   }
# # }

# # resource "google_compute_url_map" "https_redirect_url_map" {
# #   project = var.project_id
# #   name    = "${var.prefix}-https-redirect-url-map"

# #   default_url_redirect {
# #     https_redirect         = true
# #     strip_query            = false
# #     redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
# #   }
# # }

# # resource "google_compute_url_map" "alb_url_map" {
# #   project         = var.project_id
# #   name            = "${var.prefix}-alb-url-map"
# #   default_service = google_compute_backend_service.private_bucket_backend_svc.id

# #   dynamic "host_rule" {
# #     for_each = toset(local.asset_folders)
# #     content {
# #       hosts = [each.value]  # e.g., domain1.com for folder1, domain2.com for folder2
# #       path_matcher = "${each.value}-path-matcher"
# #     }
# #   }

# #   dynamic "path_matcher" {
# #     for_each = toset(local.asset_folders)
# #     content {
# #       name                = "${each.value}-path-matcher"
# #       default_backend_service = google_compute_backend_service.private_gcs_backend_svc.id

# #       path_rule {
# #         paths   = ["/${each.value}/*"]  # Matches /folder1/*, /folder2/*, etc.
# #         service = google_compute_backend_service.private_gcs_backend_svc[each.value].id
# #       }
# #     }
# #   }

# #   header_action {
# #     request_headers_to_remove = ["Cookie"]
# #   }
# # }


# # resource "google_compute_url_map" "my_url_map" {
# #   name = "my-url-map"

# #   default_url_redirect {
# #     https_redirect = true
# #     strip_query    = false
# #     prefix_redirect = "/"
# #   }




# # }

# # resource "google_compute_global_address" "alb_global_address" {
# #   # for_each = asset_folders ? toset(var.vpc.external_ips.names) : []
# #   # for_each = { for idx, asset_folder in asset_folders : idx => asset_folder }
# #   # count        = var.create_global_address ? 1 : 0
# #   project      = var.project
# #   name         = "load-balancer-ip"
# #   address_type = "EXTERNAL"
# # }
