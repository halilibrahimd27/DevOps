---
description: "Ingress ve Gateway API'nin yan yana calistirilmasi: gecis stratejisi, hibrit pattern (yeni servis Gateway, eski Ingress) ve hangisini ne zaman sececegin."
tags:
  - Networking
  - Kubernetes
  - Platform Engineering
---
# Ingress vs Gateway API — Yan Yana, Hangisi Ne Zaman

> *"2026'da Ingress 'eskiyen' ama hâlâ yaygın; Gateway API yeni ve
> standartlaşıyor. **İkisini birden yönetmek** geçiş döneminin
> gerçeği — bir cluster, iki API."*

Bu rehber Ingress + Gateway API'nin **paralel çalışması**, geçiş
stratejisi, ve "yeni servis Gateway, eski Ingress" hibrit pattern'ini
özetler.

> Detaylar:
> - [`Gateway-API-Migration.md`](Gateway-API-Migration.md) — full migration plan
> - [`Ingress-NGINX-Patterns.md`](Ingress-NGINX-Patterns.md) — Ingress production
> - [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md) — mesh side

---

## 🆚 Hızlı Karşılaştırma

| Özellik | Ingress (legacy) | Gateway API (yeni) |
|---|---|---|
| **API maturity** | GA, köklü | GA (HTTPRoute), TCPRoute beta |
| **Persona ayrımı** | Tek CRD | GatewayClass + Gateway + Route ayrı |
| **Protocol** | HTTP odaklı | HTTP, gRPC, TCP, UDP, TLS |
| **Cross-namespace** | ❌ | ✅ ReferenceGrant |
| **Traffic split** | Annotation | ✅ Native weight |
| **Controller** | Controller-spesifik annotation | Standardize |
| **Conformance** | ❌ | ✅ Test suite |

> 🔑 **2026 önerisi**: Yeni servisler **Gateway API**. Mevcut Ingress'ler **kademeli migrate**.

---

## 🌳 Hibrit Setup (Geçiş Döneminde)

```
[Cluster]
  │
  ├── ingress-nginx (Ingress controller)
  │   ├── eski-app-1 (Ingress)
  │   └── eski-app-2 (Ingress)
  │
  └── cilium / envoy gateway (Gateway controller)
      ├── yeni-app-1 (HTTPRoute)
      └── yeni-app-2 (HTTPRoute)
```

→ İki controller paralel kurulu. **Aynı LB veya ayrı**.

---

## 🔄 Migration Stratejisi (Özet)

### 1. Hafta 1: Hazırlık
- Gateway API CRD install
- Yeni Gateway controller kur (Cilium / Envoy / Contour)
- Mevcut Ingress'lere dokunmama

### 2. Hafta 2-4: Yeni servisler Gateway API'de
- Onboarding rehberi: yeni servis = HTTPRoute
- Eski'lere dokunma

### 3. Hafta 4-12: Mevcut migrate (servis-bazlı PR)
- `ingress2gateway` ile dönüş + manuel review
- Per-service PR + canary
- DNS/LB değişmez (aynı external IP)

### 4. Hafta 12-16: Sunset
- Ingress kullanımı 0 → controller uninstall

---

## 🛠️ Pratik Karar — Yeni Servis İçin

### Karar ağacı
```
Yeni servis launch'ı:
  │
  ├── HTTP only + basit?
  │     │
  │     ├── Cluster Gateway API ready mi?
  │     │     │
  │     │     ├── EVET → Gateway API (HTTPRoute)
  │     │     └── HAYIR → Ingress (ama Gateway'e geçiş yol haritasına ekle)
  │
  ├── gRPC / TCP / UDP?
  │     │
  │     └── Gateway API zorunlu (Ingress destek vermez)
  │
  ├── Multi-cluster + advanced routing?
  │     │
  │     └── Gateway API + service mesh
  │
  └── Hızlı prototype, "sonra fix ederim"?
        │
        └── Ingress (mevcut controller ile)
```

---

## 📋 Hibrit Cluster Hijyeni

### Aynı host'ta çakışma engelleme
```
example.com:
  /api/*    → Gateway API (HTTPRoute)
  /legacy/* → Ingress (eski)
```

→ **Path-based split**. Ingress 80/443, Gateway API 80/443 — DNS aynı, LB ayrı.

### Daha temiz: Subdomain split
```
api.example.com    → Gateway API (yeni)
legacy.example.com → Ingress (geçici)
```

### LB ayrımı
- Eski LB: Ingress controller'a bağlı
- Yeni LB: Gateway controller'a bağlı
- Cost +1 LB ama temiz

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Aynı host hem Ingress hem Gateway | Çakışma, debug zor | Path/subdomain ayrı |
| Migration big-bang | Production kırılması | Aşamalı + canary |
| Yeni servis Ingress'te | Tech debt | Gateway API default |
| Eski Ingress sunset planı yok | Sonsuza kadar paralel | 12-16 hafta sunset hedef |
| Gateway API'yi "henüz yeni" demek | Spec stable, çoğu controller GA | 2026'da production-ready |
| Migration tool yok | Manual çevirim hata | `ingress2gateway` |

---

## 📚 Referanslar

- **Gateway API Spec** — gateway-api.sigs.k8s.io
- **ingress2gateway** — github.com/kubernetes-sigs/ingress2gateway
- [`Gateway-API-Migration.md`](Gateway-API-Migration.md) — detaylı migration
- [`Ingress-NGINX-Patterns.md`](Ingress-NGINX-Patterns.md) — Ingress production
- [`Service-Mesh-Comparison.md`](Service-Mesh-Comparison.md)
- [`Cilium-eBPF-Intro.md`](Cilium-eBPF-Intro.md)

---

## 📋 Checklist

```
[ ] Gateway API CRD'leri kurulu ve controller (Cilium / Envoy / Contour) ayağa kalkmış
[ ] Yeni servis onboarding rehberi "default = HTTPRoute" diyor, Ingress sadece istisna
[ ] Hibrit dönemde aynı host'ta Ingress + Gateway çakışması yok (path/subdomain ayrımı net)
[ ] Eski LB (Ingress) ve yeni LB (Gateway) ayrımı veya path-split bilinçli karar olarak yazılı
[ ] Mevcut Ingress'ler `ingress2gateway` ile dönüştürülüp manuel review'dan geçiyor
[ ] Migration big-bang değil; servis-bazlı PR + canary ile ilerliyor
[ ] gRPC/TCP/UDP gereken servisler Gateway API'ye yönlendiriliyor (Ingress'te bırakılmıyor)
[ ] Eski Ingress için 12-16 haftalık sunset hedefi ve takip metriği (kalan Ingress sayısı) var
[ ] Migration sırasında DNS/external IP değişmiyor (kullanıcıya kesinti yok)
```

---

> *"2026 = **geçiş yılı**. Yeni doğanları Gateway API'de yetiştir,
> yaşlıları sevgiyle eskiyle bırak (geçici), planlı sunset ile
> yarına Gateway API-only."*
