# common
variable "project" {
  default = ""
}

variable "region" {
  default = ""
}

# lb
variable "lb" {
  type = object({
    domains = list(string)
  })
}
