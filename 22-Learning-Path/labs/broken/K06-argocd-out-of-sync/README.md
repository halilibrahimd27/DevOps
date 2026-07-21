# K06 — ArgoCD uygulaması Git ile senkron olmuyor

> Modül: [`D5`](../../../block-d-orchestration/D5-gitops-argocd.md) · Tür: kırık lab · Süre: ~45–90 dk

## Belirti

L17'de ArgoCD ile yönettiğin `lab-app` bir süredir `Synced/Healthy` idi. Bugün
farklı:

```bash
kubectl -n argocd get application lab-app
# NAME      SYNC STATUS   HEALTH STATUS
# lab-app   OutOfSync     Healthy

kubectl -n lab get deploy lab-app
# READY   Git'te 2 replica yazıyor ama cluster'da 5 var
```

Cluster Git'ten sapmış (drift) ve ArgoCD bunu **kendiliğinden düzeltmiyor**. Bir
süre bekledin, hâlâ `OutOfSync`. **Sebebi kanıtla.** README ne bozulduğunu söylemez.

## Ön koşul
- **L17'yi tamamlamış olmalısın**: `argocd` namespace'inde `lab-app` Application ve
  `lab` namespace'inde çalışan uygulama. Bu lab onun üzerine kurulur.

## Gerekenler
- `kubectl`, çalışan bir ArgoCD, (opsiyonel) `argocd` CLI.

## Kur

```bash
bash setup.sh
```

## Görevin

1. Kök sebebi **kanıtla**: cluster niçin sapmış ve ArgoCD niçin geri çekmiyor?
2. Düzelt — hem cluster'ı Git ile eşitle, hem de driftin **tekrar** kendiliğinden
   düzelmesini sağla.
3. Doğrula:
   ```bash
   bash verify.sh    # sıfır çıkış = Synced ve otomatik düzeltme açık
   ```
4. Bir `teshis.md` yaz: `OutOfSync`'i nereden gördün, `syncPolicy` neyi belirliyor.

## Kurallar

- **Önce kendin dene.** `hints/`'i sırayla aç; `solution.md` en son.
- `OutOfSync` bir hata değil bir **teşhis**: cluster ≠ Git. Sorunun kaynağı ne
  cluster'da ne Git'te — **reconciliation politikasında**.
