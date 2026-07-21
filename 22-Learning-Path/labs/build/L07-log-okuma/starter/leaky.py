#!/usr/bin/env python3
"""leaky.py — bilerek KÖTÜ log örneği. Bir sırrı düz metin loglar.
Görev: bunun neden tehlikeli olduğunu anla ve güvenli sürümünü yaz.
(Buradaki 'parola' bir placeholder'dır, gerçek değildir.)
"""
import logging
import os

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

# Placeholder — gerçek sır değil; ortamdan geldiğini varsay
password = os.environ.get("DB_PASSWORD", "<DB_PASSWORD>")

# ❌ KÖTÜ: sır düz metin log'a düşüyor — journald, dosya, SIEM, herkes görür
logging.info("kullanici giris denemesi, parola=%s", password)

# ✅ DOĞRU olurdu: sırrı hiç loglama; en fazla var/yok bilgisi
logging.info("kullanici giris denemesi, parola_saglandi=%s", bool(password))
