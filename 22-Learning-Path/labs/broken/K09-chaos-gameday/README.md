# K09 — Game day: "3 replica var, kesinti olmaz" — hipotezi sına

> Modül: [`E5`](../../../block-e-ownership/E5-chaos.md) · Tür: kırık lab (chaos game day) · Süre: ~60–120 dk

## Bu bir game day

Diğer kırık lab'lardan farkı: burada arızayı **sen kontrollü biçimde enjekte ediyorsun**.
`chaos` namespace'inde `web` servisi **3 replica** ile çalışıyor. Ekip inancı şu:

> **Hipotez:** "`web` 3 replica ile HA. Bir dağıtım/restart sırasında kesintisiz kalır."

Bu bir inanç. Game day, inancı **kanıta** çevirir. Deneyi yürüt, hipotezi sına; tutmuyorsa
altındaki **dayanıklılık zafiyetini** bul ve gider, sonra deneyi tekrarla.

> ⚠️ Blast radius **sınırlı**: tek namespace (`chaos`), tek servis (`web`), yerel `kind`.
> Gerçek kullanıcıyı vurmuyorsun. (Cluster-geneli / mesh-geneli chaos için bkz.
> [`NOT-YET.md`](../../../NOT-YET.md) — henüz hayır.)
>
> ⚠️ Tek bir zafiyet yok; bir katmanı düzeltince deney hâlâ kesinti gösterebilir.

## Gerekenler
- `kubectl` + çalışan yerel cluster (**kind** önerilir; blast radius yerelde kalır).

## Kur

```bash
bash setup.sh
```

## Deneyi yürüt (hipotezi sına)

Bir terminalde servise **sürekli** istek at, diğerinde bir dağıtımı tetikle:

```bash
# terminal 1 — kesinti sayacı (küme içinden)
kubectl -n chaos run probe --rm -i --image=busybox:1.36 --restart=Never -- \
  sh -c 'i=0; f=0; while [ $i -lt 60 ]; do \
    wget -qO- --timeout=1 http://web >/dev/null 2>&1 || f=$((f+1)); \
    i=$((i+1)); sleep 0.5; done; echo "başarısız istek: $f/60"'

# terminal 2 — chaos: dağıtımı yeniden başlat
kubectl -n chaos rollout restart deploy/web
kubectl -n chaos get pods -w
```

**Hipotez tutuyorsa** başarısız istek ≈ 0 olur. Tutmuyorsa (kesinti varsa) game day
bir **bulgu** üretti — kök nedeni bul.

## Görevin

1. **Hipotezi yaz** (`gameday.md`): "X yaparsam sistem Y şekilde ayakta kalır."
2. **Deneyi yürüt** ve sonucu ölç (kaç istek düştü, pod'lara ne oldu).
3. **Zafiyet(ler)i bul ve gider.** Deneyi tekrarladığında kesinti ~0 olana kadar devam et.
4. **Doğrula:**
   ```bash
   bash verify.sh    # sıfır çıkış = dağıtım kesintisiz + game day raporu var
   ```
5. **Raporla** (`gameday.md`): hipotez → deney → sonuç → bulunan zafiyet → **eylem maddesi
   (sahip + son tarih)** ve (gerekliyse) yeni bir alarm.

## Kurallar

- **Önce kendin dene.** `hints/`'i sırayla aç; `solution.md` en son.
- Hipotezsiz deney kurcalamadır: önce beklentini yaz, sonra enjekte et, sapmayı ölç.
- Hiçbir şey bozulmayan bir game day başarısız değildir — ama hiç zayıflık çıkmıyorsa
  kapsamı kontrollüce büyüt.
