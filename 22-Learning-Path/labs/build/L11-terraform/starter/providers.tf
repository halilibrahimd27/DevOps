# providers.tf — AWS provider'ı LocalStack'e yönlendirir. HAZIR, dokunma.
# 'test'/'test' LocalStack'in yok saydığı sahte değerlerdir — gerçek credential DEĞİL.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    ssm = "http://localhost:4566"
  }
}
