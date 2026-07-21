# Hint 2 — daralt

Application'ın senkron politikasına bak:

```bash
kubectl -n argocd get application lab-app -o jsonpath='{.spec.syncPolicy}'; echo
# boş / null
```

`syncPolicy.automated` **yok**. Yani ArgoCD "manuel" moda düşmüş: driftı görür,
`OutOfSync` gösterir, ama kendiliğinden **geri çekmez**. Birisi otomatik senkronu
kapatmış.

İki şey gerek: (1) şu anki driftı eşitle, (2) otomatik düzeltmeyi geri aç ki
bir dahaki sefere kendiliğinden toparlansın.
