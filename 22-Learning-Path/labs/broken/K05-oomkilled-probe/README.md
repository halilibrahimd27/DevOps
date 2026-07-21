# K05 — Pod sürekli yeniden başlıyor / trafik almıyor

> Modül: [`D2`](../../../block-d-orchestration/D2-k8s-production.md) · Tür: kırık lab · Süre: ~60–120 dk

## Belirti

Uygulamayı uyguladın ama Pod bir türlü kararlı olamıyor:

```bash
kubectl -n k05 get pods
# NAME         READY   STATUS             RESTARTS   AGE
# app-...      0/1     CrashLoopBackOff   5          3m
```

RESTARTS sürekli artıyor. Restart döngüsünü durdursan bile Pod `Ready` olmuyor ve
Service ona trafik göndermiyor. **Her katmanı ayrı kanıtla.** README ne bozulduğunu
söylemez.

## Gerekenler
- Yerel bir cluster (`kind`/`k3s`), `kubectl`.

## Kur

```bash
bash setup.sh
```

## Görevin

1. **Restart sebebini kanıtla.** Container niçin ölüyor? (`describe` → `Last State`).
2. Restart durunca **ikinci** soruyu sor: Pod niçin `Ready` değil? (probe).
3. İki kök sebebi düzelt (`env/deployment.yaml`), yeniden uygula.
4. Doğrula:
   ```bash
   bash verify.sh    # sıfır çıkış = kararlı + Ready
   ```
5. Bir `teshis.md` yaz: OOMKilled'ı nereden gördün, probe'un niçin başarısızdı.

## Kurallar

- **Önce kendin dene.** `hints/`'i sırayla aç; `solution.md` en son.
- `RESTARTS` sayısı bir semptom değil bir **sayaç**: sebep `Last State`'te yazılı.
