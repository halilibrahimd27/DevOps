"""L10 örnek uygulaması — test edilebilir küçük bir birim.
Pipeline'ın 'test' kapısı bu modülü doğrular."""


def normalize_tag(name: str) -> str:
    """Bir image adını registry-güvenli hâle getirir:
    küçük harf, boşluk yok, yalnız [a-z0-9-_.]."""
    out = []
    for ch in name.strip().lower():
        out.append(ch if ch.isalnum() or ch in "-_." else "-")
    return "".join(out).strip("-")


if __name__ == "__main__":
    print(normalize_tag("My App v2"))
