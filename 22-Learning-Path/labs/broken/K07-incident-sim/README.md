# K07 — "api'ye erişilemiyor" — çok-arızalı incident

> Modül: [`E3`](../../../block-e-ownership/E3-incident-postmortem.md) · Tür: kırık lab · Süre: ~60–120 dk

## Belirti

Bir uyarı geldi: `inc` namespace'indeki `api` servisi kullanıcıya cevap vermiyor.
Bir test isteği bağlanamıyor:

```bash
kubectl -n inc run t --rm -it --image=busybox:1.36 --restart=Never -- \
  wget -qO- --timeout=3 http://api
# takılıyor / bağlanamıyor
```

Service var, Deployment var, ama uygulama erişilemiyor. **Bunu bir incident gibi
yönet:** olay anından itibaren zaman damgalı not tut, kök sebe(pler)i bul ve düzelt,
sonra suçlamasız bir postmortem yaz. README ne bozulduğunu söylemez — belirti bu kadar.

> ⚠️ Burada **tek** bir arıza yok. Bir katmanı düzeltince belirti tamamen geçmeyebilir.

## Gerekenler
- `kubectl` + çalışan bir yerel cluster (**kind** önerilir; blast radius yerelde kalır).

## Kur

```bash
bash setup.sh
```

## Görevin

1. **Incident'i yönet.** `timeline.md` aç; her adımı **UTC dakika hassasiyetli** yaz
   (ör. `14:03 UTC — endpoints boş görüldü`). Bir tek karar noktası gibi davran.
2. **Kök sebe(pler)i kanıtla.** Servise niçin erişilemiyor? Belirtiyi bir tahmine
   değil, komut çıktısına bağla.
3. **Düzelt.** Belirti tamamen geçene kadar (test isteği 200 dönene kadar) devam et.
4. **Doğrula:**
   ```bash
   bash verify.sh    # sıfır çıkış = erişim geri geldi + timeline + postmortem var
   ```
5. **Postmortem yaz** (`postmortem.md`): sayısal/somut etki + kök sebep(ler) + **"niçin
   daha erken yakalanmadı"** + en az bir izlenebilir eylem maddesi (**sahip + son tarih**).

## Kurallar

- **Önce kendin dene.** `hints/`'i sırayla aç; `solution.md` en son.
- Postmortem **blameless**: dili sisteme çevir. "X kişisi yanlış yazdı" değil,
  "sistem bu yanlışın canlıya geçmesine izin verdi".
- Erişim sorununda ilk kontrol Service'in **endpoint'i**dir: arkasında pod yoksa,
  sorun ya pod'larda ya selector'dadır — ikisi de aynı anda bozuk olabilir.
