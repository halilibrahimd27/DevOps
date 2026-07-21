# resource.tf — küçük, ücretsiz kaynak (LocalStack). ADIM 2 (bütçeden SONRA).
resource "aws_s3_bucket" "demo" {
  bucket = "lab-c4-demo"
}
