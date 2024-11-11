# common
variable "project" {
  default = ""
}

variable "region" {
  default = ""
}

# iam
variable "iam" {
  type = object({
    service_account = object({
      name         = string
      display_name = optional(string)
    })
  })
}

