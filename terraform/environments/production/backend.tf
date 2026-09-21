terraform {
  backend "s3" {
    bucket = "k8s-terraform"
    key    = "production/terraform.tfstate"
    region = "ir-thr-at1"

    endpoints = {
      s3 = "https://s3.ir-thr-at1.arvanstorage.ir"
    }

    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}
