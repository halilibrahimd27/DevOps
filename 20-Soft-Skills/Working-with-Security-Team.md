# Security Ekibiyle Çalışmak — Düşman Değil, Partner

> *"Security ekibi 'nope' dediğinde DevOps ekibinin ilk içgüdüsü
> 'bypass' aramaktır — bu refleks, **ihlali öğrendiğinde tek başına
> kalmanın** garantisidir."*

Bu rehber, DevOps/SRE ile Security ekipleri arasındaki klasik
sürtünmenin **niye olduğunu**, **nasıl ortadan kalkacağını**, ve
sağlıklı işbirliğinin somut pratiklerini anlatır.

---

## 🎯 Sürtünme Niye Var?

### DevOps perspektifi
- "Velocity'imi öldürüyorlar"
- "Her PR'da güvenlik review = lansman gecikiyor"
- "Bilmiyorlar prod nasıl çalışıyor"
- "Sürekli 'no' diyorlar"

### Security perspektifi
- "Bizi sürece geç dahil ediyorlar"
- "İhlali tek başımıza taşıyoruz"
- "Yeniyi push'lamadan önce risk düşünmüyorlar"
- "Audit sırasında bana koşuyorlar"

### Gerçek
- Hedefler **uyumlu** (güvenli, hızlı yazılım)
- Süreçler **uyumsuz** (gate-keeping vs flow)
- İletişim **yetersiz** (siloluk)

---

## 🤝 İşbirliği Modeli — DevSecOps

### Klasik (kötü)
```
[Dev] → kod yaz → [DevOps] → deploy → [Security] → "DUR! Bu ihlal."
                                                    ↑
                                           son anda red, geri dönüş
```

### DevSecOps (iyi)
```
[Security] → threat model + policy + tooling
                          ↓
           guardrails (pre-commit, CI gate, admission)
                          ↓
       [Dev] kod yaz → bypass'sız geçer → [DevOps] deploy
                          ↑
            Security ekibi gate'e müdahale değil
            tooling sahibi ve danışman
```

### Felsefe değişimi
| Eski | Yeni |
|---|---|
| Security gate-keeper | Security enabler |
| Manual review | Otomatik policy |
| Son aşama check | Shift-left |
| "No" answer | "Yes, ama şu kontrolle" |
| Compliance audit-driven | Compliance continuous |

---

## 🛠️ Pratik Pratikler

### 1. Threat Model Birlikte Yapılır
Yeni servis design'da:
- Mühendis **draft** hazırlar (90 dk hafif STRIDE)
- Security ekibi **review** verir (1 saat)
- **Birlikte** action item'ları çözer

> 🔑 Security ekibi yazmasın — review etsin. Mühendis yazınca **sahiplenir**.

Bkz [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md).

### 2. Security Champions
Her dev/SRE ekibinde **bir kişi** "security champion":
- Security konularında ekibinin elçisi
- Security ekibi ile haftalık standup
- Daha derin security eğitimi alır
- Threat model fasilitatörü

> 🔑 **Champion = ekipten**. Security ekibinden gelmez. Mühendislik
> kültürüyle entegre olunca güçlü.

### 3. Office Hours
Security ekibi haftada 2-3 saat **office hour** açar:
- Her mühendis sorabilir
- "Bu pattern güvenli mi?", "Şu kütüphane CVE'si önemli mi?"
- 30 dakikalık slot bookable

### 4. Self-Service Security
Security'i **tooling'e** kuy:
- Pre-commit: gitleaks, semgrep
- CI: Trivy, OSV-Scanner
- Admission: Kyverno
- Runtime: Falco

Mühendis self-service kontrol yapar. Security ekibi tool'u maintain eder.

### 5. RFC / Design Doc'a Security Bölümü
Her RFC'de zorunlu bölüm:
```markdown
## Security Considerations
- Threat model summary
- Yeni saldırı yüzeyi
- Sensitive data handling
- AuthN / AuthZ değişiklikleri
- Incident response impact
```

PR review'a security ekibi otomatik eklenir (CODEOWNERS).

### 6. Postmortem'da Security Persp
Tüm postmortem'lerde sor:
- Bu incident security'ye yansır mı?
- Saldırgan benzer pattern'i exploit edebilir mi?
- Detection gap?

---

## 🚦 "No" Yerine "Yes, If..."

### Eski cevap
> "Bu kütüphane onaylı listede değil, kullanma."

### Yeni cevap
> "Bu kütüphane onaylı listede değil. Kabul ediyor musun:
>  1. Threat model güncellenir (15 dk)
>  2. SBOM dependency-track'e eklenir
>  3. Quarterly CVE monitor edilir
>  4. Alternatifi araştırdığını dokümanla
>  → Bu kontrollerle 'evet'."

> 🔑 **Hayır demek kolay**, "yes if" demek **danışmanlıktır**. Security
> ekibi ne kadar danışman olursa, mühendis o kadar gelir.

---

## 📊 Ortak Metrikler

Birlikte ölçtüğünüz metrikler iyi işbirliği indikatörü:

| Metrik | Hedef |
|---|---|
| **Vulnerability MTTR** | < 30 gün (CRITICAL), < 90 gün (HIGH) |
| **Mean time to patch** | < 7 gün CVE açıklandıktan |
| **Threat model coverage** | %80+ critical service |
| **Security champion her ekipte** | %100 |
| **Pre-commit + CI gate adoption** | %95+ repo |
| **Audit finding (annual)** | Trend düşüyor |
| **Security NPS (mühendis tarafından)** | > 30 |

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Security ekibi tüm PR'lara bakar | Bottleneck, yavaşlar | Otomatik gate + sample manuel review |
| Mühendis security bypass'lıyor | Gölge IT, ihlal vakti meselesi | Self-service tool + escape hatch |
| Security ekibi son aşamada gelir | "Big no" gecikme | Shift-left, design phase'de |
| "Asla bunu kullanma" listesi | Rule lawyering | "Şu kontrolle kullan" yaklaşımı |
| Security backlog görünmez | Mühendis priorize edemez | JIRA/Linear shared board |
| Security training yıllık 1 saat | Etkisiz | Quarterly + just-in-time |
| "Bu güvenli değil" — gerekçe yok | Mühendis öğrenemez | Threat eklenir, niye |
| Security tooling vendor SaaS, mühendis görmez | Black box | Open dashboard, kanıt erişimi |
| Postmortem'da security kapatılır | Detection gap kaybedilir | Security perspective her PM'de |
| Security ekibi physical olarak izole | Empati zayıf | Aynı sprint, aynı standup |

---

## 🎓 Karşılıklı Eğitim

### Mühendislere security
- Quarterly: "Top 5 OWASP" + örnek
- Threat modeling workshop (yarım gün)
- Live red team: senaryo + tartışma
- Capture the flag: oyunlaştırma

### Security ekibine mühendislik
- Sprint shadowing (security insanı sprint planning'e girer)
- Production walkthrough: deploy nasıl olur
- On-call shadowing
- Code review (kod okuma yetisi)

> 🔑 Security ekibi kod okumayı bilmiyorsa, threat model'ı sınırlı.

---

## 💬 Iletişim Tonu

### Security ekibinin söylem tarzı
**Kötü:**
- "Bu kabul edilemez."
- "Niye böyle yaptınız?"
- "Tekrar soracağım: bu policy'i bypass mı ediyorsunuz?"

**İyi:**
- "Bu yaklaşımda gördüğüm risk: X. Düşündüğümüz alternative: Y. Ekip ne der?"
- "Burada bir kontrol gerekli — birlikte bakabilir miyiz?"
- "Threat model güncellersek bunu kapatabiliriz."

### Mühendislerin söylem tarzı
**Kötü:**
- "Yine bürokrasi."
- "Onlar hep böyle, deploy'u durdururlar."
- "Bypass etmenin yolu var mı?"

**İyi:**
- "Bu tasarımdaki güvenlik risklerine bakar mısın?"
- "Hangi kontrol bu pattern'e izin verir?"
- "Çözümü beraber tasarlayalım."

---

## 📋 Sağlıklı DevSecOps İlişkisi Checklist

```
[ ] Security champions her dev/SRE ekibinde
[ ] Threat modeling: dev draft + security review
[ ] Office hours haftalık (security availability)
[ ] Self-service security tooling (gitleaks, Trivy, Kyverno)
[ ] CODEOWNERS: security path'lerde otomatik review
[ ] RFC template'inde "Security Considerations" zorunlu
[ ] Postmortem'lerde security perspective
[ ] Quarterly security training (mühendislere)
[ ] Security ekibi sprint planning'de
[ ] Shared metrics dashboard (vulnerability MTTR, etc.)
[ ] Vulnerability triage workflow (kim atar, kim çözer)
[ ] "Yes if..." dil sözlüğü ekipte
[ ] Annual: security-engineering NPS survey
[ ] CTF / red-blue team egzersizi quarterly
[ ] Security backlog public (JIRA / Linear)
```

---

## 📚 Referanslar

- **DevSecOps Manifesto** — devsecops.org
- **Building Security Champions** — OWASP
- **The Phoenix Project** — Gene Kim (kültür)
- **The Unicorn Project** — devamı
- [`08-Security/`](../08-Security/) — security deep-dives
- [`08-Security/Threat-Modeling.md`](../08-Security/Threat-Modeling.md)
- [`Stakeholder-Management.md`](Stakeholder-Management.md)

---

> *"Güvenli ekiple bireysel güvenlikte bilgili olmak yetmez —
> **mühendislik** ve **güvenlik** ekiplerinin birbirini anlaması yeter.
> Aynı dili konuşmayan iki ekip, aynı binayı **iki ayrı** bina sanır."*
