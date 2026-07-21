# main.tf (referans çözüm) — uygulamanın altyapısı kod olarak. Önce KENDİN dene.

resource "aws_s3_bucket" "artifacts" {
  bucket = "lab-app-artifacts"
}

resource "aws_ssm_parameter" "app_port" {
  name  = "/lab-app/app_port"
  type  = "String"
  value = "8000"
}

output "bucket" {
  value = aws_s3_bucket.artifacts.bucket
}
