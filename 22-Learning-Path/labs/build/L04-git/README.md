# L04 — Git: branch, conflict, merge vs rebase

> Modül: [`A4`](../../../block-a-intuition/A4-git-temeli.md) · Süre: ~1 saat · Kırık lab: yok

Sıfırdan bir repo kurar, iki dal açar, **bilerek bir conflict üretip çözer**;
sonra aynı işi bir kez `merge`, bir kez `rebase` ile yapıp geçmiş grafiğinin
nasıl farklılaştığını görürsün. Conflict korkusu, onu kontrollü bir ortamda
bir kez yaşayınca gider.

## Gerekenler
- `git` (2.x). Başka bir şey gerekmez — tamamen yerel.

## Görev

1. **Repoyu kur.** `starter/init-lab.sh` `./repo` altında tek commit'li bir başlangıç
   yaratır (`notlar.md` dosyası).
   ```bash
   bash starter/init-lab.sh && cd repo
   ```
2. **Conflict üret ve çöz.**
   - `main`'den `feature-merge` dalı aç, `notlar.md`'nin **aynı satırını** değiştir, commit et.
   - `main`'e dön, **aynı satırı farklı şekilde** değiştir, commit et.
   - `feature-merge`'i `main`'e `merge` et → **conflict**. Elle çöz, `add` + commit.
3. **Aynı işi rebase ile yap.**
   - Başlangıca benzer bir kurulumla `feature-rebase` dalı aç, bir commit ekle.
   - `main`'e `rebase` et (`git rebase main`), grafiğin **doğrusal** kaldığını gör.
4. **Farkı yaz.** `git log --oneline --graph --all` çıktısını incele. `report.txt`'e:
   merge bir **birleştirme commit'i** bırakır; rebase geçmişi **doğrusal** tutar ama
   commit'leri yeniden yazar. Hangisi ne zaman? Kendi cümlelerinle.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `repo/` en az bir **merge commit** içeriyor (`git log --merges` boş değil).
- [ ] `report.txt` "merge commit" ve "rebase → doğrusal geçmiş" ayrımını açıklıyor.

## İpucu (çözüm değil)
- Conflict işaretleri: `<<<<<<<`, `=======`, `>>>>>>>`. İkisini de sil, doğru
  içeriği bırak, `git add`, sonra commit.
- Yarıda kaldıysan `git merge --abort` / `git rebase --abort` seni geri getirir — panik yok.
- Grafiği gör: `git log --oneline --graph --all`.
- **Kural:** paylaşılmış (push edilmiş) dalları rebase etme — geçmişi yeniden yazmak
  başkalarının kopyasını bozar.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
