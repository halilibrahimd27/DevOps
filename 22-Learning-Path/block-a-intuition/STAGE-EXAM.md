---
description: "Blok A sınavı: Linux, ağ, DNS/HTTP/TLS, Git, Bash ve elle deploy — A→B geçiş kapısı. Her soru bir modülün kabul kriterine bağlı."
level: A
tags: [Learning Path, Stage Exam]
---
# 📝 Blok A Sınavı — Sezgi

> *"A → B geçiş sinyali: bir servisin neden ayağa kalkmadığını, dokümana bakmadan üç komutla daraltabiliyor musun?"*

**Kapı:** Blok A sonu (A6'dan sonra, B1'den önce) · **Ön koşul:** [`A1`](A1-linux-temeli.md)–[`A6`](A6-elle-deploy.md) kabul kriterleri geçilmiş

Bu sınav yeni bir konu öğretmez; öğrendiklerinin **kanıtıdır.** İki parça vardır:
yazılı kavram soruları ve elle çalıştırılan uygulamalı görev. Ölçüt "biliyorum"
değil — komutun çalışması, çıktının doğru olması ve gerekçeni yazabilmen. Her soru
bir modülün kabul kriterine izlenebilir (sağdaki sütun); bu sınav yeni ölçüt icat
etmez, mevcut kabul kriterlerini tek oturumda toplar.

> 📌 **Nasıl alınır:** Modül dokümanlarını **kapat.** Cevapları önce yaz/çalıştır,
> sonra kendi modülünle karşılaştır. Kopyaladığın bir cevap seni B'ye geçirmez —
> B1'de gerçek bir kırık sistemin karşısında yalnız kalırsın.

---

## 1️⃣ Kavram soruları (yazılı)

Her birini **kendi cümlelerinle** yaz. "Doğru" cevap modülünde; önce sen yaz.

| # | Soru | İzlenebilirlik (modül → kabul kriteri) |
|---|---|---|
| 1 | `640` iznini octal ve `rwx` olarak açıkla; üç kitle (sahip/grup/diğerleri) her biri ne yapabilir? Bunu "en az yetki" ilkesine bağla. | A1 → izin + kullanıcı/grup kriteri |
| 2 | "disk dolu"nun iki farklı anlamı (`df -h` vs `df -i`) nedir? Hangisi inode tükenmesidir? | A1 → `df -h`/`df -i` kriteri |
| 3 | "Connection refused" ile "connection timed out" farkı ne? Her biri hangi katmanda neyi işaret eder? | A2 → refused/timeout kriteri |
| 4 | `127.0.0.1:80` dinleyen bir servis niçin "dışarıdan erişilemez"? `0.0.0.0` ile farkı? | A2 → `127.0.0.1`/`0.0.0.0` kriteri |
| 5 | HTTP durum kodu sınıfları (`2xx/3xx/4xx/5xx`) ne anlatır? `4xx` ile `5xx` sorumluluğu kimde? | A3 → durum kodu kriteri |
| 6 | Bir TLS sertifikası için expired / name-mismatch / chain hatalarından her biri ne demek? | A3 → sertifika kriteri |
| 7 | "Paylaşılanı rebase etme" altın kuralı niçin var? Merge ile rebase geçmişi nasıl farklılaşır? | A4 → merge/rebase kriteri |
| 8 | `set -euo pipefail`'in üç bayrağı ayrı ayrı neyi engeller? Her biri için bir örnek. | A5 → `set -euo pipefail` kriteri |

**Geçme:** 8 sorunun **en az 7'sini**, modüle bakmadan, teknik olarak doğru ve
kendi cümlelerinle yaz. Ezber tanım değil, *niçin*i olan cevap.

---

## 2️⃣ Uygulamalı görev — "ayağa kalkmayan servis"

Bu görev A1–A6'yı tek senaryoda birleştirir ve A→B sinyalinin ta kendisidir.

**Görev A — Kırık servisi teşhis et (çekirdek):**
[`K00 — systemd ayağa kalkmıyor`](../labs/broken/K00-systemd-ayaga-kalkmiyor/) kırık
lab'ını çöz. `README.md` yalnız belirtiyi verir; sebebi sen bulacaksın.

- [ ] `bash ../labs/broken/K00-systemd-ayaga-kalkmiyor/verify.sh` sıfır hatayla geçiyor
- [ ] Kök sebebi ve **teşhis akışını** (belirti → daraltma → kök sebep → düzeltme → doğrulama) yazdın
- [ ] En fazla `hint-1`/`hint-2` kullandın; `hint-3`/`solution.md` açtıysan bu sefer geçmedin sayılır

**Görev B — Elle deploy'un ayakta olduğunu kanıtla:**
[`A6`](A6-elle-deploy.md)/[`L06`](../labs/build/L06-elle-deploy/) kurulumunu kullan.

- [ ] `systemctl is-enabled app` → `enabled` **ve** `systemctl is-active app` → `active`
- [ ] `curl -s http://127.0.0.1/health` nginx üzerinden `200` + beklenen gövde
- [ ] `ss -tlnp` çıktısında app yalnız `127.0.0.1`, nginx `0.0.0.0:80` dinliyor — gösterdin

**Görev C — Katman daraltma (zamanlı):** Görev A'daki arızayı bulurken kullandığın
**ilk üç komutu** ve her birinin niçin o sırada geldiğini yaz. Süre hedefi: doküman
açmadan **5 dakikanın altında** doğru katmana inmek.

---

## 🚫 Bu sınavı kendine karşı kaybetme

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `solution.md`'yi açıp K00'ı "çözmek" | Teşhis kasını hiç çalıştırmadın | Belirtiden başla, hint'leri **kademeli** aç |
| "Anladım" deyip geçmek | Öznel; B1'de kanıtlanmaz | Komut çıktısı + yazılı gerekçe göster |
| `chmod 777` ile izin sorununu susturmak | Sorunu gizler, en az yetkiyi bozar | Eksik olan **tek** biti ver |
| Tahminle "DNS'tir" demek | Kanıt yok; B bloğunun tam tersi | `dig`/`ss`/`curl` ile **hangi katman** olduğunu göster |
| Görev C'yi atlamak | Asıl ölçülen şey daraltma disiplini | Üç komutu ve sırasının gerekçesini yaz |

---

## ✅ Geçtin mi?

Üçü de doğruysa Blok B'ye hazırsın:
- [ ] Kavram: 8/8'in en az 7'si doğru + gerekçeli
- [ ] Uygulama: K00 `verify.sh` yeşil (hint ≤2) **ve** A6 reboot-safe kanıtı
- [ ] Daraltma: bir arızayı üç komutla, doküman açmadan doğru katmana indirdin

Geçemediysen utanılacak bir şey yok — **hangi soru/görevde takıldıysan o modüle dön.**
Örn. Görev A'da katmanı bulamadıysan A2, TLS'te takıldıysan A3. Sınav seni geri
göndermek için değil, **nereye döneceğini söylemek** için var.

## ⏭️ Sırada
Geçtiysen: [`B1 — Log Okuma`](../block-b-visibility/B1-log-okuma.md).
Geçemediysen: takıldığın modüle dön, kabul kriterlerini tekrar geç.

---

> *"Bir servisin neden çalışmadığını üç komutla daraltamıyorsan, onu görebilir hâle getirmek (Blok B) henüz erken."*
