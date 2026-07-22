---
description: "Tehdit modelleme + uyum (KVKK / GDPR / SOC 2): riski ve regülasyonu mühendislik kontrolüne çevirmek."
level: F
module: F2
estimated_hours: 12
prerequisites: [D1, D4]
tags: [Learning Path, Security, Compliance]
---
# F2 — Tehdit Modelleme + Uyum (KVKK / GDPR / SOC 2)

> *"Uyum bir belge değil, mühendislik kontrollerinin bir dile çevrilmiş hâlidir."*

**Blok:** F — Karar · **Süre:** ~12 saat · **Ön koşul:** [`D1`](../block-d-orchestration/D1-k8s-temel.md), [`D4`](../block-d-orchestration/D4-supply-chain.md)

## 🎯 Bu modülü bitirdiğinde
- Bir sistem için basit bir tehdit modeli çıkarır, riskleri önceliklendirirsin.
- Bir regülasyon gereksinimini (KVKK / GDPR / SOC 2) somut bir mühendislik kontrolüne bağlarsın.
- "Kabul edilebilir risk" kararını gerekçesiyle yazılı savunursun.

## 🧠 Niye bu, niye şimdi
D1'de RBAC/NetworkPolicy, D4'te supply chain güvenliğini kurdun — bunlar birer
kontrol. F2 o kontrolleri bir **risk ve uyum çerçevesine** oturtur: neyi, kime
karşı, hangi yükümlülükle koruyorsun?

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`08-Security/Threat-Modeling.md`](../../08-Security/Threat-Modeling.md) | STRIDE çerçevesi + şablon | ~35 dk |
| [`19-Compliance/KVKK-Practical.md`](../../19-Compliance/KVKK-Practical.md) | bir regülasyonu mühendislik kontrolüne çevirme örneği | ~30 dk |
| [`19-Compliance/SOC2-Type2-Prep.md`](../../19-Compliance/SOC2-Type2-Prep.md) | kontrol ↔ kanıt eşlemesi | ~25 dk |

## 🔨 Teslim edilebilir egzersiz
Çıktısı yazılı bir tehdit modeli + kontrol haritasıdır. D1–D5'te kurduğun sistemi
(ya da Capstone 2'yi) seç. `tehdit-modeli.md` yaz:
1. Varlıkları ve güven sınırlarını çıkar (ne değerli, nereden nereye veri geçiyor).
2. STRIDE benzeri bir tabloyla en az 5 tehdit listele, her birine bir kontrol eşle
   (D1 RBAC/NetworkPolicy, D3 secret, D4 image tarama/imza — hangisi hangi tehdidi kapatıyor).
3. Bir KVKK/GDPR/SOC 2 gereksinimini **somut** bir kontrole bağla (madde → kontrol → nasıl kanıtlanır).
4. Kapatmadığın bir riski **açıkça** yaz: hangi riski kabul ettin, niçin, hangi koşulda yeniden bakılır.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] `tehdit-modeli.md`'de varlık + güven sınırı + en az 5 tehdit → kontrol satırı olan bir tablo var
- [ ] En az bir regülasyon maddesi somut bir kontrole ve o kontrolün kanıtına bağlandı (madde → kontrol → kanıt)
- [ ] Kabul edilen bir risk gerekçesiyle yazılı: niçin kabul edildi, hangi koşulda yeniden değerlendirilir
- [ ] Her tehdide eşlenen kontrol D1–D4 modüllerinden birine izlenebilir (kaynak modül adı yazılı)

## 🧪 Kendini test et
1. STRIDE'daki "R" (Repudiation / inkâr) tehdidini hangi mühendislik kontrolü kapatır ve niçin denetim kaydı bir uyum gereksinimidir?
2. "Uyumluyuz" cümlesini bir denetçiye nasıl kanıtlarsın — beyanla mı, kanıtla mı, hangisiyle?
3. Bir riski kapatmak orantısız pahalıysa (kontrol maliyeti > korunan değer) ne yaparsın?

<details><summary>Cevaplar</summary>

1. İnkârı, kim ne yaptığını değiştirilemez biçimde kaydeden **denetim kaydı** (audit log) kapatır; uyum çerçeveleri bunu "kim, ne, ne zaman" sorusunun cevabı olduğu için zorunlu tutar — [`08-Security/Threat-Modeling.md`](../../08-Security/Threat-Modeling.md).
2. Kanıtla. Denetçi beyana değil, kontrolün çalıştığını gösteren artefakta bakar (log, config, pipeline çıktısı). Kanıtı otomatikleştirmek asıl iştir — [`19-Compliance/Audit-Evidence-Automation.md`](../../19-Compliance/Audit-Evidence-Automation.md).
3. Riski bilinçli kabul edersin: kararı, gerekçesini ve tekrar bakılacak koşulu yazılı olarak kaydedersin. Kabul edilen risk sessiz olmaz, belgelenir — [`08-Security/Threat-Modeling.md`](../../08-Security/Threat-Modeling.md).
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Tehdit listesi bitmiyor | Güven sınırı çizilmedi | Önce veri nereden nereye geçiyor çiz; tehditleri sınır geçişlerinde ara |
| Regülasyon soyut kalıyor | Madde kontrole bağlanmadı | Her maddeyi "hangi kontrol, hangi kanıt" sorusuna indir; bağlanamayan madde boşluktur |
| Her risk "kapatılmalı" deniyor | Kabul edilebilir risk kavramı yok | Kontrol maliyetini korunan değerle karşılaştır; kapatmadığını gerekçesiyle yaz |
| Kontrol var ama kanıt yok | Denetim izi tasarlanmadı | Kontrolün çalıştığını gösteren log/config'i şimdiden üret; sonradan çıkarılamaz |

## 💼 Portfolyo çıktısı
Bir tehdit modeli + kontrol haritası — güvenlik karar vericiliğinin kanıtı.

## ⏭️ Sırada
[`F3 — Platform, IDP, Team Topologies`](F3-platform-idp.md)

---

> *"'Uyumluyuz' demek kolaydır; hangi kontrolün hangi maddeyi karşıladığını göstermek mühendisliktir."*
