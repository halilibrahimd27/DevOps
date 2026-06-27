---
description: "Vim hayatta kalma rehberi: cikma, kaydetme, undo, modlar ve temel duzenleme. Usta olmak degil, production sunucusunda 2 dakikada config duzeltip cikmak icin."
---
# Vim Survival Guide

> *"Vim'den nasıl çıkarım?"* — `:q!` (Enter)
> *"Aman tanrım, ne yaptım?"* — `u` (undo)

Bu cheatsheet "Vim ustası olun" değil, "production sunucusunda 2 dakikada
config düzelt çık" amaçlıdır.

## 🚪 ÇIKMA (en önemli)

| Komut | Ne yapar |
|---|---|
| `:q` | Çık (değişiklik yoksa) |
| `:q!` | **Zorla çık** (değişiklikleri at) |
| `:w` | Kaydet |
| `:wq` veya `:x` veya `ZZ` | Kaydet ve çık |
| `:wa` | Tüm açık buffer'ları kaydet |
| `:qa!` | Tümünden zorla çık |

## 🎮 Modlar

```
NORMAL  ─┐ esc ┌─ INSERT (yazma)
         │     │
         ├─────┼─ VISUAL (seçme)
         │     │
         └─────┴─ COMMAND (`:` ile)
```

- **NORMAL** mod = navigasyon ve komutlar (varsayılan)
- `Esc` ile her zaman normal moda dön

## 🧭 Hareket (NORMAL modda)

```
        ↑
        k
    ←  h ↓  l →
        j
        ↓

w        sonraki kelime
b        önceki kelime
e        kelimenin sonuna
0        satır başı
^        satırdaki ilk karakter
$        satır sonu
gg       dosya başı
G        dosya sonu
:42      42. satıra git
H/M/L    ekranın başı/ortası/sonu
Ctrl+u   yarım sayfa yukarı
Ctrl+d   yarım sayfa aşağı
Ctrl+f   tam sayfa aşağı
Ctrl+b   tam sayfa yukarı
%        eşleşen parantez (), [], {}
```

## ✏️ Insert mod'a geç

```
i        cursor'un öncesinde insert
a        cursor'un sonrasında insert (append)
I        satır başında insert
A        satır sonunda insert
o        altına yeni satır + insert
O        üstüne yeni satır + insert
```

## 🗑️ Sil / Kes

```
x        cursor altındaki karakter
dd       satır sil
3dd      3 satır sil
d$       cursor'dan satır sonuna
dw       cursor'dan kelime sonuna
diw      kelimeyi sil (cursor kelimenin neresinde olursa)
di"      "..." içini sil (içerik)
da"      "..." dahil sil
di(      (...) içini sil
dG       cursor'dan dosya sonuna
dgg      cursor'dan dosya başına
```

> 💡 **Tüm `d` komutları yapıştırılabilir** — Vim "delete" değil "cut" yapar.

## 📋 Kopyala / Yapıştır

```
yy       satırı kopyala
3yy      3 satır
y$       cursor'dan satır sonuna kopyala
yw       kelimeyi
y/foo    cursor'dan "foo"ya kadar
p        cursor'dan SONRA yapıştır
P        cursor'dan ÖNCE yapıştır
```

## ↩️ Undo / Redo

```
u            undo
Ctrl+r       redo
U            satırın değişikliklerini geri al
.            son komutu tekrarla (POWER!)
```

> 💎 **`.` komutu** = Vim'in en güçlü silahı. Ne yaptıysan tekrarlar.

## 🔍 Arama

```
/foo       ileri ara
?foo       geri ara
n          sonraki eşleşme
N          önceki
*          cursor altındaki kelimeyi ara (ileri)
#          cursor altındaki kelimeyi ara (geri)

:noh       arama vurgusunu kapat
```

## 🔄 Bul / Değiştir

```
:s/eski/yeni/          satırda ilk eşleşme
:s/eski/yeni/g         satırda hepsi
:%s/eski/yeni/g        dosyada hepsi
:%s/eski/yeni/gc       sor-onayla
:%s/\<eski\>/yeni/g    word-boundary (sadece tam kelime)

# Range ile (10. satırdan 20.ye)
:10,20s/eski/yeni/g

# Visual seçimden sonra:
:'<,'>s/eski/yeni/g
```

## 👀 Visual mod (seçme)

```
v        karakter karakter seç
V        satır seç
Ctrl+v   blok (column) seç — POWER mode

# Seçtikten sonra:
y        kopyala
d        sil
>        sağa indent
<        sola indent
=        otomatik indent
:        komut çalıştır seçili satırlarda
```

## 📚 Buffer / Window / Tab

```bash
:e <FILE>       dosyayı aç
:bn             sonraki buffer
:bp             önceki buffer
:bd             buffer'ı kapat
:ls             buffer listesi

:split          ekranı yatay böl
:vsplit         ekranı dikey böl
Ctrl+w h/j/k/l  pencereler arası hareket
Ctrl+w =        pencereleri eşitle
Ctrl+w q        pencereyi kapat

:tabnew <FILE>  yeni tab
:tabnext        sonraki tab (gt)
:tabprev        önceki tab (gT)
```

## 💾 Kaydetme & Acil

```
:w                  kaydet
:w <FILE>           başka isim olarak
:w !sudo tee %      sudo gerekti unutmuştun (ROOT işlemi)
:e!                 dosyayı diskteki haline geri al
:earlier 10m        son 10 dakikayı undo
:later 10m          tekrar redo
```

## 🎨 Görsel ayar

```
:set number             satır numarası (kısa: :set nu)
:set relativenumber     göreli (kısa: :set rnu)
:set list               görünmez karakterleri göster
:set hlsearch           arama vurgusu
:set ignorecase         case-insensitive arama
:set smartcase          büyük harf yazınca case-sensitive
:set paste              auto-indent kapatır (paste için)
:syntax on              syntax highlighting

:colorscheme desert     tema
```

## 📐 Indent / Format

```
>>          satırı 1 indent sağa
<<          1 indent sola
==          satırı otomatik indent
gg=G        tüm dosyayı indent et
gqq         satırı 80 char'a göre wrap

:set tabstop=2 shiftwidth=2 expandtab
```

## 🪄 Pratik kombinasyonlar

```
ciw "yeni"          kelimeyi sil + insert "yeni" yaz
ci"  "yeni"         "..." içini değiştir
df.                 cursor'dan ilk noktaya kadar sil
yy p                satır duplicate
:%!sort             tüm dosyayı sort komutuna pipe et
:%!jq .             tüm dosyayı jq ile format et
:r !date            mevcut konuma `date` çıktısını ekle
:r <FILE>           başka dosyanın içeriğini ekle
ggVG                tüm dosyayı seç
```

## 🆘 Acil senaryolar

| Sorun | Çözüm |
|---|---|
| "Çıkamıyorum!" | `Esc` `:q!` `Enter` |
| "Yanlış bir şey yaptım" | `u` (undo), tekrar `u` |
| "ESC tuşu yok" (terminalde) | `Ctrl+[` aynı şey |
| "sudo unuttum, kaydedemiyor" | `:w !sudo tee %` ardından `:q!` |
| "Satır numarası istiyorum" | `:set nu` |
| "Tüm değişiklikleri at, baştan" | `:e!` |
| "Read-only diyor" | `:set noreadonly` veya `:w!` |
| "Swap file warning" | başka biri açtı; `D` (delete swap) ya da `R` (read-only) |
| "Son saatte ne yaptım?" | `:earlier 1h` |
| "Vim'siz yaşam mümkün" | `nano <FILE>` 😉 |

## 🔌 .vimrc minimum

```vim
" ~/.vimrc — production sunucusu için minimum
set nocompatible
set number
set relativenumber
set tabstop=2 shiftwidth=2 expandtab
set autoindent smartindent
set ignorecase smartcase
set hlsearch incsearch
set mouse=a
set clipboard=unnamedplus
syntax on

" Sudo kaydet (kısayol)
cmap w!! w !sudo tee > /dev/null %
```
