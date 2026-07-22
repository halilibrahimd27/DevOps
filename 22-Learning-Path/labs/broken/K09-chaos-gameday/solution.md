# K09 — Çözüm: Game Day ("3 replica = HA" hipotezi)

> Önce kendin dene ve `gameday.md`'ni yaz. Bu dosya iki zafiyeti ve deney akışını
> verir — cevabı değil, cevaba nasıl varıldığını.

## Hipotez neden tutmadı
"3 replica → kesintisiz" inancı iki bağımsız zafiyet yüzünden yanlış:

**Zafiyet 1 — `strategy.type: Recreate`.**
`rollout restart` bu strateji altında TÜM pod'ları aynı anda indirip sonra yenilerini
kaldırır. Üç replica'nın hepsi bir anda gider → tam kesinti. `RollingUpdate` (varsayılan)
+ `maxUnavailable` küçük tutulursa her an en az bir pod ayakta kalır.

**Zafiyet 2 — `readinessProbe` yok.**
Service, pod `Running` olur olmaz ona trafik yollar — nginx henüz isteğe cevap veremese
bile. Sonuç 5xx / düşen istek. readinessProbe, pod gerçekten hazır olana kadar Service'in
onu backend'e almasını engeller.

(Ek: PodDisruptionBudget de yok → drain/gönüllü kesinti tüm replica'ları birden alabilir.)

## Teşhis akışı
1. Deneyi yürüt (README probe döngüsü) → başarısız istek sayısını ölç (≈0 değil).
2. `kubectl -n chaos rollout restart deploy/web` sırasında `kubectl -n chaos get pods -w`
   → tüm pod'ların AYNI anda `Terminating` olduğunu gör (Recreate kanıtı).
3. `kubectl -n chaos get deploy web -o yaml | grep -A2 strategy` → `Recreate`.
4. `kubectl -n chaos get deploy web -o yaml | grep -i readiness` → boş (probe yok).

## Düzeltme
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1        # her an en az 2 pod ayakta
      maxSurge: 1
  template:
    spec:
      containers:
        - name: web
          readinessProbe:      # hazır olmayan pod trafik almaz
            httpGet: { path: /, port: 8080 }
            initialDelaySeconds: 2
            periodSeconds: 3
```
İsteğe bağlı ama doğru: bir `PodDisruptionBudget` (`minAvailable: 2`) ekle.

## Deneyi tekrarla
Düzeltmeden sonra probe döngüsünü yeniden çalıştır → başarısız istek ~0 olmalı.
`verify.sh` bunu ve `gameday.md` raporunun varlığını kontrol eder.

## Ne öğrendin
"Replica sayısı" tek başına HA değildir. Dayanıklılık; dağıtım stratejisi + hazırlık
kontrolü + kesinti bütçesinin birlikte doğru kurulmasıdır. Ve asıl ders yöntemde:
bir inancı ("HA'yız") kontrollü bir deneyle kanıta çevirmek — game day'in özü budur.
Bu, E5'in ve production sahipliğinin çekirdeği.
