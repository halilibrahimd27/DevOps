# Hint 1 — yön

Hatayı sonuna kadar oku — Terraform sana kimin kilidi tuttuğunu **söylüyor**:

```bash
cd env && terraform plan
```

Çıktıda `Lock Info` bloğu var: `ID`, `Who`, `Created`, `Operation`. Bu, kilidi
yaratan işlemin kimliği. Kilit "canlı" bir apply'a mı ait, yoksa **çoktan ölmüş**
bir işlemden mi kaldı? (İpucu: şu an çalışan bir terraform var mı? `Created` zamanı ne?)
