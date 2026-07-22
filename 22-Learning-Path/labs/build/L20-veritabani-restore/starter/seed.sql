-- L20 — kaynak DB'ye 1000 satır sipariş yükler (restore doğrulaması için sabit sayı).
CREATE TABLE orders (
  id         serial PRIMARY KEY,
  customer   text NOT NULL,
  amount     numeric(10,2) NOT NULL,
  created_at timestamptz DEFAULT now()
);

INSERT INTO orders (customer, amount)
SELECT 'musteri-' || g, (g % 500 + 1)::numeric(10,2)
FROM generate_series(1, 1000) AS g;
