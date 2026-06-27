# variables.tf — tip-güvenli, açıklamalı, validation'lı girdiler

variable "name" {
  description = "Kaynak adı (kebab-case, ortam adı dahil değil)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.name))
    error_message = "name kebab-case olmalı (3-40 karakter, küçük harf/rakam/tire)."
  }
}

variable "environment" {
  description = "Dağıtım ortamı."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment yalnız dev | staging | prod olabilir."
  }
}

variable "tags" {
  description = "Modül kaynaklarına eklenecek ek etiketler."
  type        = map(string)
  default     = {}
}
