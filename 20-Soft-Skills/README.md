# 20 · Soft Skills — Mühendislikten Daha Önemli (Bazen)

> *"En iyi mimari kararı veren mühendis, **yanlış kişiye** anlatınca
> kararını uygulayamaz. Soft skill 'soft' değil, **leverage'dir**."*

DevOps/SRE/Platform işleri **insanla** ilgilidir — ekibinle, geliştiricilerle,
yöneticilerle, vendor'larla. Bu bölüm "kodun nasıl yazılacağı" değil,
**işin nasıl döneceği**ne dair pratiklerin derlemesi.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Oncall-Sustainability.md`](Oncall-Sustainability.md) | On-call'da burnout önleme, vardiya tasarımı, post-incident dinlenme |
| [`Stakeholder-Management.md`](Stakeholder-Management.md) | Üst yönetim, ürün, security, legal — kime ne dilde anlatırsın |
| [`Working-with-Security-Team.md`](Working-with-Security-Team.md) | Security ekibiyle düşman değil partner ilişkisi |
| _`Vendor-Management.md`_ *(yakında)* | RFP, vendor lock-in, müzakere, escape stratejisi |
| _`Saying-No.md`_ *(yakında)* | "Hayır" demenin sanatı: scope creep, premature commitment |
| _`Postmortem-Conversation.md`_ *(yakında)* | Blameless culture'i konuşmaya nasıl yansıtırız |
| _`Mentoring-Junior-Engineers.md`_ *(yakında)* | Junior'a infra/SRE öğretmenin pratikleri |
| _`Documentation-as-Communication.md`_ *(yakında)* | RFC, ADR, design doc — bunları yazmak ve okumak |

## Felsefe

> Mühendislik 0 → 1 problemi çözer. Soft skills 1 → N **scaling**'ini
> çözer. Tek başına bir mühendis 5'i koordine eden mühendisten kat be
> kat geride kalır.

## Türkçe-spesifik notlar

Türk iş kültüründe sıkça karşılaşılan dinamikler:
- **Hiyerarşik karar**: "Müdür ne der?" — DevOps takımı genelde "yönetimden geçen" değişiklik bekler. Bu pattern'i değiştirmek için yetkilendirme.
- **Yüz-yüze tercihi**: Async iletişim (PR review, RFC) yerine toplantı baskısı. Toplantı kültürü vs RFC kültürü dönüşümü.
- **"Hayır" söylemekten kaçınma**: Üstüne aldığın işi yapamadığında daha büyük problem. Saying-No kültürü.
- **Junior'ın "soru sorma" çekincesi**: Pakistan/Türkiye/Hindistan kıdem kültüründe junior soru sormaktan korkar. Mentoring akışı buna duyarlı.

## Anti-pattern'ler

- ❌ "Soft skill'ler önemli değil, koda odaklan" → 5 yıl sonra senior yine aynı junior
- ❌ Tüm iletişim toplantı ile → async culture yok, dokuman eskir
- ❌ Security ekibi düşman → bypass'lar başlar, gölge IT
- ❌ Üst yönetime teknik dilde anlatım → karar gecikir, bütçe alınmaz
- ❌ Vendor'a tam güven → lock-in, eskalasyon imkansız
- ❌ Burnout sinyalleri görmezden → senior istifa, kurum bilgi kaybeder
