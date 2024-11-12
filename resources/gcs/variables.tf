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
    location                    = string
    storage_class               = string
    public_access_prevention    = string
    uniform_bucket_level_access = bool
    versioning = object({
      enabled = bool
    })
  })
}

# lb
variable "lb" {
  type = object({
    domains = list(string)
  })
}
