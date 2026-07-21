# L05 — Bash: güvenli, argümanlı, shellcheck'ten temiz script

> Modül: [`A5`](../../../block-a-intuition/A5-bash.md) · Süre: ~1 saat · Kırık lab: yok

İki argüman alan, hataya karşı sağlam (`set -euo pipefail`), bir log dosyasını
özetleyip sonucu bir rapor dosyasına yazan ve `shellcheck`'ten **temiz** geçen bir
script yazarsın. Ops işinin yarısı bu tür küçük, güvenilir scriptlerdir.

## Gerekenler
- `bash`, `grep`, `wc`. Tercihen `shellcheck` (yoksa verify.sh bu kontrolü atlar).

## Görev

`./summarize.sh <log-dosyası> <rapor-dosyası>` şeklinde çağrılan bir script yaz:

1. **Argümanları doğrula.** Tam iki argüman gelmezse anlamlı bir hata basıp
   `exit 1` yap. Log dosyası yoksa yine hata ver.
2. **Sağlamlık.** İlk satırlarda `set -euo pipefail` olsun — tanımsız değişken,
   sessiz hata ve pipe hatası scripti durdursun.
3. **Özetle.** Rapor dosyasına en az şunları yaz:
   - `toplam satır: N`
   - `ERROR: M` (log'daki hata satırı sayısı)
   - en sık geçen 3 log seviyesi (INFO/WARN/ERROR sayımı)
4. **Temiz kod.** `shellcheck summarize.sh` uyarısız geçsin (tırnaklama, `[[ ]]`,
   `local`, `"$var"`).

`starter/` bir iskelet ve test log'u içerir; `starter/summarize.sh.template`'i
`./summarize.sh` olarak kopyalayıp doldur.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `./summarize.sh` `set -euo pipefail` içeriyor ve iki argüman doğruluyor.
- [ ] `./summarize.sh starter/sample.log out.txt` sıfır çıkışla `out.txt` üretiyor.
- [ ] `shellcheck` kuruluysa uyarı yok.

## İpucu (çözüm değil)
- Argüman sayısı: `[[ $# -ne 2 ]] && { echo "kullanım: ..."; exit 1; }`.
- Sayım: `grep -c ERROR "$LOG"`. Seviye dağılımı: `grep -oE 'INFO|WARN|ERROR'` +
  `sort | uniq -c | sort -rn`.
- `set -e` ile bir komutun sıfırdan farklı dönmesi normalse `|| true` ekle.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
