# K04 — Pod'lar ayağa kalkmıyor / servise erişilemiyor

> Modül: [`D1`](../../../block-d-orchestration/D1-k8s-temel.md) · Tür: kırık lab · Süre: ~60–120 dk

## Belirti

Uygulamayı cluster'a uyguladın ama iki şey birden yanlış:

```bash
kubectl -n k04 get pods
# NAME                       READY   STATUS             RESTARTS   AGE
# app-...                    0/1     ImagePullBackOff   0          2m

# Pod'u zorla düzeltsen bile servise ulaşamıyorsun:
kubectl -n k04 run probe --image=busybox:1.36 --restart=Never -it --rm -- \
  wget -qO- --timeout=3 http://app-svc || echo "erişilemedi"
```

Bu bir **çok-arızalı** lab (Blok D böyle olur): bir sorunu çözünce ikincisi kalır.
Belirtiler ayrı, sebepler ayrı. **Her katmanı ayrı kanıtla.** README ne bozulduğunu
söylemez.

## Gerekenler
- Yerel bir cluster (`kind create cluster --name lab-d1`), `kubectl`.
- NetworkPolicy uygulayan bir CNI (kind'ın `kindnet`'i uygular).

## Kur

```bash
bash setup.sh
```

## Görevin

1. **Katman katman daralt.** Önce Pod niçin `ImagePullBackOff`? (`describe`) Sonra
   Pod `Running` olunca servise niçin ulaşılamıyor? (ağ katmanı)
2. Her iki kök sebebi düzelt (`env/` içindeki manifestleri düzelt, yeniden uygula).
3. Doğrula:
   ```bash
   bash verify.sh    # sıfır çıkış = ikisi de çözüldü
   ```
4. Bir `teshis.md` yaz: her katman için hangi komut, hangi kanıt.

## Kurallar

- **Önce kendin dene.** `hints/`'i sırayla aç; `solution.md` en son.
- "Bir şeyi düzelttim, hâlâ çalışmıyor" → muhtemelen **ikinci** bir sorun var.
  Tek seferde tek katman.
