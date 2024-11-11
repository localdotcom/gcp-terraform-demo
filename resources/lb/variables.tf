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
    domain = string
  })
}
