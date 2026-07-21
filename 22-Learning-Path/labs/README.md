# Lab'lar — inşa et ve tamir et

> *"Tutorial 'şunu kur' der; kırık lab 'şunu tamir et' der. İkincisi mühendis yetiştirir."*

Bu dizin patikanın **elle iş** kısmıdır. Okumak bir modülü bitirmez —
lab'ın `verify.sh`'i sıfır hatayla geçince biter.

## İki tür lab

| Tür | Dizin | Ne yaparsın | Ne öğretir |
|---|---|---|---|
| İnşa | `build/L##-<slug>/` | Sıfırdan bir şey kurarsın | Bir soyutlamanın *ne çözdüğünü* |
| Kırık | `broken/K##-<slug>/` | Bilerek bozulmuş bir sistemi tamir edersin | Teşhis — asıl mühendislik becerisi |

## İnşa lab'ının anatomisi

```
README.md    # görev, adımlar, kabul kriterleri, ipucu (çözüm değil)
starter/     # başlangıç iskeleti
solution/    # referans çözüm — önce KENDİN dene
verify.sh    # mekanik doğrulama: sıfır çıkış = geçti
```

## Kırık lab'ının anatomisi

```
README.md    # SADECE belirti — ne bozulduğunu söylemez
setup.sh     # ortamı bilerek bozuk kurar
hints/       # kademeli: hint-1 (yön) → hint-2 (daralt) → hint-3 (neredeyse cevap)
solution.md  # önce TEŞHİS AKIŞI, sonra kök sebep
verify.sh    # düzeltildi mi kontrol eder
```

## Kural

- Kırık lab'da **önce kendin dene.** `hints/`'e sırayla bak; `solution.md`'yi
  ancak `hint-3` de yetmezse aç. Cevaba erken bakmak, öğrenmeyi çalmaktır.
- Her `verify.sh` çıkış kodu **0** dönene kadar modül bitmez.
- Lab'lar **yerel-önce**: Docker, `kind`/`k3s`, LocalStack, tek VM. Bulut yalnız
  C4'ten sonra ve **bütçe alarmı** kurulduktan sonra.

## Bağımlılıklar

Lab'ları çalıştırmadan önce her `README.md`'nin **"Gerekenler"** bölümüne bak.
Genel araç seti: `bash`, `git`, `curl`, `ss` (veya `netstat`), `docker`, `python3`.
Her lab kendi ek bağımlılığını (örn. `kind`, `terraform`, `openssl`) listeler.
