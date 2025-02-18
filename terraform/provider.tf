
terraform {
  required_providers {
    warren = {
      source = "WarrenCloudPlatform/warren"
      version = "0.1.3"
    }
  }
 backend "s3" {
  skip_region_validation      = true # avoid Error: Invalid region value
  skip_credentials_validation = true # avoid Error: validating provider credentials
  skip_requesting_account_id  = true # avoid Error: Retrieving AWS account details
  skip_metadata_api_check = true # don't add AWS metadatas (x-amz-storage-class, ...)
  skip_s3_checksum = true # disable some AWS specific checks
  use_path_style = true # disable prefixed bucket in URL
 }
}

provider "warren" {
  api_url = "https://api.denv-r.com/v1"
  api_token = "${var.api_token}"
}
