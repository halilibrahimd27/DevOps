# L17 — GitOps: tek uygulamayı ArgoCD ile Git'ten yönet

> Modül: [`D5`](../../../block-d-orchestration/D5-gitops-argocd.md) · Süre: ~3 saat · Kırık lab: [`K06`](../../broken/K06-argocd-out-of-sync/)

Şimdiye kadar `kubectl apply` ile **elle** deploy ettin. GitOps bunu tersine çevirir:
Git deposu **tek gerçek kaynaktır**, cluster ona uyar. Bu lab tek bir uygulamayı
ArgoCD ile Git'ten yönetir, sonra elle bir drift yaratıp ArgoCD'nin bunu `OutOfSync`
gösterip düzelttiğini gözlemler. Karmaşık desenler (App-of-Apps, ApplicationSet)
**yok** — önce tek app sağlam çalışsın (bkz. [`NOT-YET.md`](../../../NOT-YET.md)).

## Gerekenler
- D1'deki kind cluster, `kubectl`.
- ArgoCD (kind'a kur): `kubectl create namespace argocd` + resmi install manifesti.
- Uygulama manifestlerini koyacağın bir **Git deposu** (fork/kendi repo'n).

## Görev

1. **ArgoCD'yi kur ve giriş yap.**
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f <argocd-install-manifest>
   kubectl -n argocd port-forward svc/argocd-server 8080:443   # UI
   ```
2. **Uygulama manifestlerini Git'e koy.** `starter/app/` içindeki Deployment+Service'i
   kendi Git depona koy (ör. `apps/lab/` yolu).
3. **Application CR'ı yaz (SEN).** `starter/application.yaml`'daki TODO'ları doldur:
   `repoURL` senin depon, `path` manifest yolu, `destination` bu cluster, `syncPolicy`
   otomatik (self-heal açık).
   ```bash
   kubectl apply -f starter/application.yaml
   kubectl -n argocd get applications         # Synced / Healthy olmalı
   ```
4. **Drift yarat.** Cluster'da elle değişiklik yap (Git'i değiştirmeden):
   ```bash
   kubectl -n lab scale deploy/lab-app --replicas=5
   kubectl -n argocd get applications         # OutOfSync
   ```
   Auto-sync + self-heal açıksa ArgoCD replica'yı Git'teki değere **geri çeker**.
   Kapalıysa `argocd app sync` ile sen düzelt. Her iki yolu da dene.
5. **Raporla.** `report.txt`'e: `Synced/Healthy` çıktısı, drift sonrası `OutOfSync`
   çıktısı, ve "Git tek gerçek kaynak" ilkesinin bir operasyonel sonucu — elle yapılan
   değişiklik niçin geri alınır?

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `application.yaml` bir `argoproj.io` `Application`; `source` (repoURL+path),
      `destination` ve `syncPolicy` içeriyor.
- [ ] `report.txt` uygulamanın `Synced/Healthy` olduğunu gösteriyor.
- [ ] `report.txt` elle yaratılan drift'in `OutOfSync` gösterildiğini ve düzeltildiğini
      içeriyor.
- [ ] `report.txt` "Git tek gerçek kaynak"ın bir operasyonel sonucunu anlatıyor.

## İpucu (çözüm değil)
- `syncPolicy.automated.selfHeal: true` → cluster Git'ten saparsa ArgoCD geri çeker.
  `prune: true` → Git'ten silinen kaynak cluster'dan da silinir.
- "OutOfSync" bir hata değil bir **teşhis**: cluster ile Git ayrıştı demek. Düzeltme
  ya Git'i güncelle (kalıcı) ya sync et (geçici, drift tekrar gelir).
- Elle `kubectl edit` yapmak GitOps'ta anti-pattern'dir — değişiklik Git'te yoksa bir
  sonraki sync'te **kaybolur**. Bu bilerek böyledir (K06'da yaşayacaksın).

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
