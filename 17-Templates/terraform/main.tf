# main.tf — Terraform modül iskeleti
# Kopyala, <PLACEHOLDER>'ları kendi kaynağına göre doldur.

terraform {
  required_version = ">= 1.5"

  required_providers {
    # Örnek: AWS. Kendi provider'ına göre değiştir.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Ortak etiketler — her kaynağa uygulanır (cost allocation + sahiplik için)
locals {
  common_tags = merge(
    {
      "managed-by"  = "terraform"
      "module"      = var.name
      "environment" = var.environment
    },
    var.tags,
  )
}

# Örnek kaynak — kendi kaynağınla değiştir.
# resource "aws_<RESOURCE>" "this" {
#   name = var.name
#   tags = local.common_tags
# }
