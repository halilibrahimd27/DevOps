# MODULE-SPEC — A1…F5 Tam Modül Şartnamesi

> ⏸️ **Bu dosya onay kapısıdır (§10 Faz 0 / §14.2-a).** Kullanıcı incelemeden
> Faz 2 (içerik yazımı) başlamaz. Faz 1 iskeleti onay beklerken yapılabilir.

**Kaynak:** [`GAP-MAP.md`](GAP-MAP.md) · **Blok tasarımı:** BUILD-PROMPT §4.2

**Süre tahmini uyarısı (§3.5):** Aşağıdaki `saat` sütunu Faz 0 tahminidir; haftada
10–12 saat çalışan biri içindir. Kesin saat, içerik yazılırken (Faz 2+) her modülün
frontmatter'ında netleşir. Süreyi kısa göstermek güven kaybetmenin en hızlı yoludur —
tahminler cömert tutuldu.

---

## Ana tablo

| ID | Modül adı | Blok / L | Saat | Ön koşul | Kaynak durumu | Build lab | Kırık lab |
|---|---|---|---|---|---|---|---|
| A1 | Linux temeli: process, filesystem, izin, kullanıcı/grup | A / L0 | 12 | — | 🔴 EKSİK | L01 | — |
| A2 | Ağ I: TCP/IP, port, routing | A / L0 | 8 | A1 | 🔴 EKSİK | L02 | — |
| A3 | Ağ II: DNS → HTTP → TLS/sertifika | A / L0 | 10 | A2 | 🔴 EKSİK | L03 | — |
| A4 | Git temeli: commit, branch, merge, rebase, conflict | A / L0 | 8 | A1 | 🟡 KISMİ | L04 | — |
| A5 | Bash + ops için Python (iş görecek kadar) | A / L0 | 14 | A1, A4 | 🔴 EKSİK | L05 | — |
| A6 | Bir uygulamayı **elle** ayağa kaldır (VM+nginx+DB+systemd+log, container YOK) | A / L0 | 16 | A1–A5 | 🔴 EKSİK | L06 | — |
| B1 | Log okuma: journalctl, structured logging, ne loglanır | B / L0 | 8 | A6 | 🔴 EKSİK | L07 | — |
| B2 | Metrik: Prometheus temeli, "neyi ölçersin", cardinality | B / L0 | 10 | A6, B1 | 🟡 KISMİ | L08 | — |
| B3 | **İlk kırık lab** — kırık VM sisteminde arıza bulma | B / L0 | 8 | B1, B2 | 🔴 EKSİK | — | **K01** |
| C1 | Container: image, katman, multi-stage, docker compose | C / L1 | 12 | A6, B3 | 🟢 VAR | L09 | K02 |
| C2 | CI: test → build → artifact → registry | C / L1 | 12 | A4, C1 | 🟢 VAR | L10 | — |
| C3 | Terraform — A6'yı otomatikleştir | C / L1 | 14 | A6, C1 | 🟢 VAR | L11 | **K03** |
| C4 | Bulut temelleri + **bütçe alarmı** (ilk bulut modülü) | C / L1 | 10 | C3 | 🟡 KISMİ | L12 | — |
| D1 | K8s temel: Pod/Deployment/Service/Ingress — **RBAC+NetworkPolicy ilk günden** | D / L1 | 18 | C1, C2 | 🟡 KISMİ | L13 | **K04** |
| D2 | K8s production: request/limit, probe, PDB, HPA | D / L1 | 14 | D1 | 🟢 VAR | L14 | **K05** |
| D3 | Secret yönetimi | D / L1 | 10 | D1 | 🟢 VAR | L15 | — |
| D4 | Supply chain: image tarama + imzalama — **C2 pipeline'ının devamı** | D / L1 | 12 | C2, D1 | 🟢 VAR | L16 | — |
| D5 | GitOps (ArgoCD) — tek uygulama | D / L1 | 12 | D1, C2 | 🟢 VAR | L17 | **K06** |
| E1 | SLI / SLO / error budget | E / L1 | 10 | B2, D2 | 🟢 VAR | L18 | — |
| E2 | Alerting + on-call disiplini | E / L1 | 8 | E1, B1 | 🟢 VAR | L19 | — |
| E3 | Incident response + blameless postmortem | E / L1 | 10 | E2 | 🟢 VAR | — | **K07** |
| E4 | Veritabanı production — özellikle **restore** | E / L1 | 12 | A6, D2 | 🟢 VAR | L20 | **K08** |
| E5 | İleri kırık lab / chaos | E / L1 | 10 | E3, D2 | 🟢 VAR | — | **K09** |
| F1 | Maliyet ve trade-off (FinOps) | F / L2 | 8 | C4, D2 | 🟢 VAR | — | — |
| F2 | Tehdit modelleme + uyum (KVKK/GDPR/SOC 2) | F / L2 | 10 | D1, D4 | 🟢 VAR | — | — |
| F3 | Platform, IDP, Team Topologies | F / L2 | 8 | D5, F1 | 🟢 VAR | — | — |
| F4 | Yazma: ADR, RFC, postmortem | F / L2 | 8 | E3 | 🟢 VAR | — | — |
| F5 | Stakeholder yönetimi, "hayır" demek, vendor | F / L2 | 8 | F3 | 🟢 VAR | — | — |

**Toplam modül:** 28 (A:6, B:3, C:4, D:5, E:5, F:5) · **Build lab:** 20 (L01–L20) · **Kırık lab:** 9 (K01–K09)

---

## Süre denetimi (§14.3)

| Blok | Modül saati toplamı | Yorum |
|---|---|---|
| A | 68 | En ağır — sıfırdan temel. Kasıtlı zahmetli (A6) |
| B | 26 | Görünürlük; kısa ama kırık lab (K01) burada |
| C | 48 | Mevcut deep-dive güçlü → yazım hafif, lab ağır |
| D | 66 | ≥60 ✓ (§14.3 alarmı geçildi). Güvenlik ipliği D1/D4'te içeride |
| E | 50 | Tamamı mevcut deep-dive sarımı + lab/kırık lab |
| F | 42 | Üçüncü bakış; okuma ağırlıklı, lab yok |
| **TOPLAM** | **~300 saat** | Haftada 10–12 saat → **~25–30 hafta** (blok başına aralık Faz 1 README'de) |

> Not: Blok C–F'de modül gövdesi kısadır (mevcut deep-dive'lara link + köprü); saatin
> büyük kısmı **okuma + lab** üzerinedir, yeni içerik değil. Bu, §3.1'in "modül 200 satırı
> geçmesin" kuralıyla uyumludur.

---

## Bağımlılık grafiği (DAG — döngü yok)

Faz 1'de `CURRICULUM.md`'ye mermaid olarak çizilecek. Metinsel ön kontrol:

```
A1 → A2 → A3 ─┐
A1 → A4 ───────┤
A1 → A5 (A4) ──┤
               └→ A6 → B1 → B2 → B3
B3 → C1 → C2 ──┐         C1 → C3 → C4
C1 ────────────┴→ D1 → {D2, D3, D4(+C2), D5(+C2)}
D2 → E1(+B2) → E2(+B1) → E3 → {E5(+D2), F4}
A6+D2 → E4
C4+D2 → F1 → F3(+D5) → F5
D1+D4 → F2
```

**Kontrol (Faz 1 çıktı kapısı için ön-doğrulama):**
- ✅ Her modülün her ön koşulu kendisinden **önce** geliyor (ID sırası + blok sırası korunuyor).
- ✅ Döngü yok (yukarıdaki ok yönleri tek yönlü, geri kenar yok).
- ✅ Blok sınırları korunuyor: hiçbir modül sonraki bloğu ön koşul saymıyor.
- ✅ A1 hiçbir şeyi ön koşul saymıyor (tek giriş noktası — 3 rampa da buraya/A6'ya bağlanır).

---

## Kırık lab dağılımı (§7.2)

| Blok | Kırık lab | Gerçekçi arıza türü (taslak) |
|---|---|---|
| A | **yok** | Kasıtlı: henüz inşa edilmiş bir şey yok ki bozulsun. Kırık lab "B3'ten itibaren omurga" (§7.2) |
| B | K01 (B3) | Servis ayağa kalkmıyor: yanlış izin / port çakışması / disk dolu / systemd unit hatası |
| C | K03 (C3) [+ K02 (C1) opsiyonel] | Terraform state lock / drift · (K02: image tag / port mapping) |
| D | K04, K05, K06 | ImagePullBackOff · yanlış label selector · RBAC forbidden · OOMKilled · eksik probe · ArgoCD out-of-sync |
| E | K07, K08, K09 | Incident sim (çok-arızalı) · restore başarısız · chaos/game day |
| F | **yok** | Karar bloğu — uygulamalı arıza değil, trade-off/yazım |

> §7.2 "her blokta en az bir" kuralı, kırık lab'ın "B3'ten itibaren omurga" çerçevesiyle
> okunur: **B, C, D, E** her birinde ≥1 (D ve E'de birden fazla ✓). **A** ve **F** doğaları
> gereği hariç (A: inşa öncesi sezgi; F: karar/yazım). Bu yorum "Açık kararlar"a yazıldı.

---

## Sertifika kapıları (§8.2) — F bloğuna paralel

| Kapı | Konum | Sertifika | Karşılayan modüller |
|---|---|---|---|
| G1 | Blok C sonu | KCNA **veya** Terraform Associate | C1, C2, C3, C4 |
| G2 | Blok D sonu | CKA | D1, D2, D3, D5 |
| G3 | Blok E sonu | CKS **veya** AWS SAA | CKS: D1, D3, D4, F2 · SAA: C3, C4, F1 |

Detay + `HOW-TO-CERTIFY.md` + çelişki temizliği → **Faz 6.5**.

---

## Modül anatomisi notları (yazım için, Faz 2+)

Her modül BUILD-PROMPT §6 iskeletini izler. Kaynak durumuna göre gövde ağırlığı:

- **🔴 EKSİK (A1–A3, A5, A6, B1, B3):** Öğretici gövde tam yazılır ama yine de §3.1
  "200 satır" tavanına dikkat — temel kavram + lab'a devret, ansiklopedi yazma.
- **🟡 KISMİ (A4, B2, C4, D1):** Kısa giriş köprüsü (kavram + "niye") + mevcut deep-dive'a
  "Önce oku" ile devret. Köprü 5–15 satır ya da en fazla kısa modül gövdesi.
- **🟢 VAR (C1–C3, D2–D5, E1–E5, F1–F5):** Modül **sıralayıcıdır**: "niye bu, niye şimdi" +
  "Önce oku" tablosu (≥1 mevcut repo dosyası) + lab + kabul kriteri. Açıklayıcı içerik
  tekrar edilmez → linke çevrilir.

**Güvenlik ipliği (§4.2 D bloğu):** D1 RBAC+NetworkPolicy'siz yazılamaz; D4 ayrı güvenlik
dersi değil, C2 pipeline'ının devamıdır. Bu iki modülün "Önce oku" tablosu `08-Security/`
dosyalarını **ilk günden** içerir.

---

## Açık kararlar (bu fazda alınan varsayımlar)

1. **Modül sayısı 28** (BUILD-PROMPT §4.2'nin 28 ID'sinin birebir karşılığı). Blok içinde
   bölme (`D1a`/`D1b`) yapılmadı; gerekirse Faz 2/3'te bölünebilir (§4.2 izin veriyor).
2. **Süre tahminleri Faz 0 taslağıdır**, cömert tutuldu. Faz 2+ içerik yazılırken netleşir.
3. **Kırık lab: A ve F hariç** (yukarıdaki gerekçe). §7.2'nin katı okunuşuyla A/F'ye de
   koymak gerekirse kolayca eklenir — ama doğaları gereği zorlama olur.
4. **K02 (C1 kırık lab) opsiyonel** işaretlendi; C bloğunun zorunlu kırık lab'ı K03'tür.
5. **Lab numaralandırma sürekli** (L01–L20, K01–K09), bloktan bağımsız artan. Modül ID'si
   ayrı eksen; bir modülde hem build hem kırık lab olabilir (örn. C3 → L11 + K03).

---

## ⚠️ ONAY REVİZYONLARI (kullanıcı — Faz 0 kapısı)

MODULE-SPEC onaylandı ANCAK aşağıdaki 9 revizyon Faz 1 iskeletine
uygulanacak. Faz 1 bu bölümü girdi alır.

1. **200 satır tavanı yeniden tanımlandı.** §3.1'deki tavan yalnızca
   🟢 VAR (sıralayıcı) modüller içindir. 🔴 EKSİK modüller reponun tek
   öğretici içeriğidir: hedef **400–700 satır**. 🟡 KISMİ: 200–400.

2. **A5 bölündü.** `A5 = Bash` (12s, A6 ön koşulu). Python ayrıldı:
   yeni `C0 — Ops için Python` (30s), ön koşul A5, C2'nin ön koşulu.
   A6 ön koşulu `A1–A5` → **`A1–A4, A5`** (Python değil).

3. **A4 ve D1 kaynak durumu 🟡 → 🔴 (temeller kısmı).**
   `01-Git-Workflow/` ve `05-Kubernetes/` temel içermiyor, ileri
   workflow/production içeriyor. A4: 8→12s. D1: 18→28s.

4. **Süre tahminleri revize.** Blok toplamları: A 97 · B 36 · C 88 ·
   D 84 · E 64 · F 48 · Capstone 60 = **~477 saat ≈ 40-48 hafta**.
   Modül bazlı dağılımı Faz 1'de netleştir. 300 saat kabul edilmiyor.

5. **A6'ya kırık lab eklendi: K00** — "systemd servisi ayağa
   kalkmıyor" (port çakışması / yanlış path / izin). K8s bilgisi
   gerektirmez, debugging sezgisi burada başlar.

6. **K02 zorunlu** (opsiyonel değil). Container hataları yeni
   başlayanın en sık takıldığı yer.

7. **G3 kapısı düzeltilecek.** CKS eşlemesinden `F2` çıkarılacak
   (ileriye bağımlılık) VEYA G3 Blok F sonrasına alınacak. Faz 6.5'te
   karara bağla, `Açık kararlar`a yaz.

8. **Capstone'lar spec'e eklenecek:** C1-capstone (Blok C sonu),
   C2-capstone (Blok D sonu), C3-capstone (Blok E sonu). Her biri
   ~20s. Faz 1 iskeletinde yer alsın.

9. **Blok F'ye teslim edilebilir egzersiz.** En az F1 (maliyet
   hesaplama egzersizi) ve F4 (gerçek bir ADR + postmortem yaz,
   rubrikle değerlendir). 42 saat saf okuma kabul edilmiyor.

**B2 notu:** `Prometheus-Grafana-K8s-Setup.md` K8s tabanlı, B2 ise
D'den önce. B2'nin "Önce oku" tablosunda kullanılamaz — yalnızca
`Prometheus-Best-Practices.md`.
