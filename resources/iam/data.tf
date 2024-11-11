data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "${var.project}-tfstate"
    prefix = "gcs"
  }
}
