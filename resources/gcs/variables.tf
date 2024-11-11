# common
variable "project" {
  default = ""
}

variable "region" {
  default = ""
}

# gcs
variable "gcs" {
  type = object({
    buckets                     = list(string)
    location                    = string
    storage_class               = string
    public_access_prevention    = string
    uniform_bucket_level_access = bool
    versioning = object({
      enabled = bool
    })
  })
}
