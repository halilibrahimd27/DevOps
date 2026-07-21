"""Pipeline'ın ilk kapısı. Kırmızıysa build çalışmaz."""
from app import normalize_tag


def test_lowercase_and_dash():
    assert normalize_tag("My App") == "my-app"


def test_strips_edges():
    assert normalize_tag("  hi  ") == "hi"


def test_keeps_dots_and_digits():
    assert normalize_tag("v2.1") == "v2.1"
