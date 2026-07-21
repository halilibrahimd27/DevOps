# Hint 2 — daralt

Kilit bilgisi bir dosyada duruyor:

```bash
cat env/.terraform.tfstate.lock.info
```

Şu an çalışan bir terraform süreci **yok** (`ps aux | grep terraform`). Yani bu bir
**bayat kilit** — işlem öldü ama kilidi geride bıraktı. Kilidi güvenle kaldırabilirsin.

Doğru araç dosyayı elle silmek değil, Terraform'un kendi komutudur. Kilit ID'sini
hata mesajından (veya dosyadan) al; birazdan onunla açacaksın.
