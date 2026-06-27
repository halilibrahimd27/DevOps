# outputs.tf — modülü tüketen kaynaklar için çıktılar
# Çıktıları, modülü çağıranın gerçekten ihtiyaç duyduğu değerlerle sınırla.

output "name" {
  description = "Modülün oluşturduğu kaynağın normalize adı."
  value       = var.name
}

output "tags" {
  description = "Kaynaklara uygulanan birleşik etiket seti."
  value       = local.common_tags
}

# Örnek: oluşturulan kaynağın ID'si
# output "id" {
#   description = "Oluşturulan kaynağın ID'si."
#   value       = aws_<RESOURCE>.this.id
# }
