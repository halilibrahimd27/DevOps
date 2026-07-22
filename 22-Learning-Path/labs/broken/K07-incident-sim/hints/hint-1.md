# Hint 1 — yön

Servise erişemiyorsun. Bir Service "erişilemiyor"sa ilk soru **tahmin değil**: arkasında
çalışan bir pod (endpoint) var mı?

```bash
kubectl -n inc get endpoints api
```

Endpoint listesi **boşsa**, Service hiçbir pod'a bağlı değildir. O zaman iki olasılık
var ve **ikisi de** aynı anda doğru olabilir:
- arkada çalışan pod **yok** (pod'lar Running değil), ya da
- pod'lar çalışıyor ama Service onları **etiketten bulamıyor** (selector).

Bir sonraki adımda ikisini ayrı ayrı ele al. (Ve bunu incident gibi yönet: her
gözlemi `timeline.md`'ye zaman damgasıyla yaz.)
