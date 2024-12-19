
terraform {
  required_providers {
    warren = {
      source = "WarrenCloudPlatform/warren"
      version = "0.1.3"
    }
  }
#  backend "s3" {
#    bucket = "s3-tf"
#    key = "terraform-state"
#    region = "nte01"
#    skip_region_validation      = true
#    skip_credentials_validation = true
#    skip_requesting_account_id  = true
#  }
}

provider "warren" {
  api_url = "https://api.denv-r.com/v1"
  api_token = "${var.api_token}"
}
