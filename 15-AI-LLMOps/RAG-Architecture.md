# RAG Architecture — Retrieval-Augmented Generation

> *"LLM 'her şeyi bildiğinden' emin olduğu **halüsinasyonun**
> üretmesi, şirket dokümanına bakıp 'bu cümle nereden?' sorusuna
> cevap veremediğindendir. **RAG** = LLM'e kütüphane vermek."*

Bu rehber Retrieval-Augmented Generation mimarisini — embedding,
vector store, retriever, reranker, generation — production'da
kurmanın somut yollarını anlatır.

---

## 🎯 RAG Nedir?

> **RAG**: LLM'in sadece training data'sından değil, **dış kaynaktan**
> bilgi çekerek yanıt vermesi.

```
[User Query]
     │
     ▼
[Embedding Model] ──► [Query vector]
                            │
                            ▼
                  [Vector Store]
                  (similarity search)
                            │
                            ▼
                  [Top-K relevant chunks]
                            │
                            ▼
[Optional: Reranker] ──► [Refined chunks]
                            │
                            ▼
[Prompt Template]
  "Cevapla bu context'le:
   {chunks}
   
   Soru: {query}"
                            │
                            ▼
                       [LLM]
                            │
                            ▼
                    [Cevap + citations]
```

---

## 📐 RAG'in Bileşenleri

### 1. **Document Ingestion Pipeline**
```
[Source: PDF, Markdown, Confluence, web]
     │
     ▼
[Chunker]   (semantic boundary, token limit)
     │
     ▼
[Embedding Model]  (sentence transformer / OpenAI)
     │
     ▼
[Vector Store]
```

### 2. **Query Pipeline**
```
[Query] → [Embedding] → [Vector search] → [Rerank] → [LLM context]
```

### 3. **Generation**
```
[Context + Query] → [LLM] → [Response + Citations]
```

---

## 🛠️ Tech Stack — Yaygın Seçimler

| Bileşen | Seçenekler |
|---|---|
| **Embedding model** | OpenAI `text-embedding-3-small`, BGE-M3, multilingual-e5 |
| **Vector store** | pgvector (Postgres ext), Pinecone, Weaviate, Qdrant, Milvus |
| **Retriever** | Plain similarity, hybrid (BM25 + vector) |
| **Reranker** | Cohere Rerank, BGE-Reranker, ColBERT |
| **LLM** | Claude / GPT-4 / Gemini / Llama (open-source) |
| **Framework** | LangChain, LlamaIndex, Haystack |
| **Orchestration** | Temporal / Airflow (batch ingestion) |

> 🔑 **Türkçe için**: BGE-M3 multilingual + Claude / GPT-4 (Türkçe destek mükemmel).

---

## 📦 1️⃣ Document Ingestion

### Chunking strategy
```python
# Semantic chunking (önerilen)
from langchain.text_splitter import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,           # token (~750 char)
    chunk_overlap=50,         # context köprüsü
    separators=["\n\n", "\n", ". ", "? ", "! ", " ", ""]
)

chunks = splitter.split_text(document)
```

### Metadata enrichment
```python
chunks_with_meta = [
    {
        "content": chunk,
        "metadata": {
            "source": "internal-wiki/payments-runbook.md",
            "section": "Refund Policy",
            "last_updated": "2026-04-15",
            "owner_team": "payments-team",
            "lifecycle": "production",
            "language": "tr"
        }
    }
    for chunk in chunks
]
```

> 🔑 Metadata sayesinde **filtre** yapabilirsin: "sadece son 6 ayda güncellenmiş + payments team".

### Embedding generation
```python
from openai import OpenAI

client = OpenAI()

def embed(text: str) -> list[float]:
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=text
    )
    return response.data[0].embedding   # 1536-dim vector

embeddings = [embed(c["content"]) for c in chunks_with_meta]
```

### Vector store insert (pgvector)
```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT,
  metadata JSONB,
  embedding vector(1536),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);
CREATE INDEX ON documents USING gin (metadata);
```

```python
import psycopg
from pgvector.psycopg import register_vector

conn = psycopg.connect(...)
register_vector(conn)

for chunk, emb in zip(chunks_with_meta, embeddings):
    conn.execute(
        "INSERT INTO documents (content, metadata, embedding) VALUES (%s, %s, %s)",
        (chunk["content"], json.dumps(chunk["metadata"]), emb)
    )
```

---

## 🔍 2️⃣ Retrieval

### Plain similarity search
```sql
-- pgvector cosine similarity
SELECT content, metadata, 1 - (embedding <=> %s) AS similarity
FROM documents
WHERE metadata->>'lifecycle' = 'production'
ORDER BY embedding <=> %s
LIMIT 5;
```

### Hybrid search (BM25 + vector)
```sql
-- Postgres: tsvector + pgvector birleştir
WITH bm25 AS (
  SELECT id, ts_rank(to_tsvector('turkish', content), query) AS bm25_score
  FROM documents, plainto_tsquery('turkish', %s) query
  ORDER BY bm25_score DESC LIMIT 20
),
vector_search AS (
  SELECT id, 1 - (embedding <=> %s) AS vec_score
  FROM documents
  ORDER BY embedding <=> %s LIMIT 20
)
SELECT d.content, d.metadata,
  (0.5 * COALESCE(b.bm25_score, 0) + 0.5 * COALESCE(v.vec_score, 0)) AS final_score
FROM documents d
LEFT JOIN bm25 b ON b.id = d.id
LEFT JOIN vector_search v ON v.id = d.id
ORDER BY final_score DESC
LIMIT 10;
```

> 🔑 Hybrid search ~%20-30 daha iyi. Spesifik isim/kod araması için BM25, semantic için vector.

---

## 🎯 3️⃣ Reranker (Opsiyonel ama güçlü)

İlk retrieval 20 chunk → reranker en alakalı 5'i seçer.

### Cohere Rerank
```python
import cohere

co = cohere.Client(<API_KEY>)

results = co.rerank(
    query="Kredi kartı iadesi nasıl?",
    documents=[c["content"] for c in retrieved_chunks],
    model="rerank-multilingual-v3.0",
    top_n=5
)

reranked = [retrieved_chunks[r.index] for r in results]
```

### BGE-Reranker (open-source)
```python
from FlagEmbedding import FlagReranker

reranker = FlagReranker('BAAI/bge-reranker-v2-m3', use_fp16=True)
scores = reranker.compute_score([[query, c["content"]] for c in retrieved_chunks])
top5 = sorted(zip(retrieved_chunks, scores), key=lambda x: -x[1])[:5]
```

---

## 💬 4️⃣ Generation

### Prompt template
```python
PROMPT = """Sen bir DevOps asistanısın. Sana verilen kontekst'i kullanarak soruya cevap ver.

Kurallar:
1. SADECE kontekst'teki bilgiyi kullan.
2. Bilgi kontekst'te yoksa "Bu konuda bilgim yok" de.
3. Her cevabın sonunda kaynak alıntıla [Source: filename, section].
4. Türkçe cevap ver.

Kontekst:
{context}

Soru: {question}

Cevap:"""

context = "\n\n---\n\n".join([
    f"[Source: {c['metadata']['source']}, {c['metadata']['section']}]\n{c['content']}"
    for c in reranked
])

response = anthropic.messages.create(
    model="claude-opus-4-7",
    max_tokens=1024,
    messages=[{"role": "user", "content": PROMPT.format(context=context, question=query)}]
)
```

---

## 🛡️ Production Concerns

### 1. **Halüsinasyon kontrolü**
- Citation zorunlu — her claim için kaynak
- "Bilmiyorum" demeye cesaret prompt'a yaz
- Output'ta source URL/path mutlaka

### 2. **Latency**
- Embedding: ~50ms
- Vector search: ~10-100ms (HNSW)
- Reranker: ~200-500ms
- LLM: 1-5s
- **Total**: 2-6s

### 3. **Cost**
- Embedding: $0.0001 / 1K token (OpenAI small)
- Vector store: storage + index
- LLM: $1-15 / 1M token (model'e göre)

### 4. **Freshness**
- Document update → re-ingest
- Incremental: sadece değişen chunk'lar
- Schedule: nightly cron + on-event webhook

### 5. **Security**
- PII filtering ingestion'da
- Per-user access control: metadata'da `allowed_groups`
- Vector store ayrı service (compromise blast radius)

---

## 🎯 Evaluation

### Metrikler
| Metrik | Açıklama |
|---|---|
| **Retrieval@K** | Top-K'da relevant chunk var mı? |
| **MRR** (Mean Reciprocal Rank) | Relevant chunk hangi sırada? |
| **Faithfulness** | LLM cevabı kontekst'le tutarlı mı? (hallucination ölçümü) |
| **Answer Relevance** | Cevap soruya yanıt veriyor mu? |
| **Context Precision** | Kontekst'in kaçı gerçekten alakalı? |

### Tool: Ragas
```python
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_precision

results = evaluate(
    dataset=eval_dataset,
    metrics=[faithfulness, answer_relevancy, context_precision]
)
```

### Test set
- **Manual curation**: 100-300 soru-cevap çifti
- **LLM-generated**: GPT-4 ile sentetik
- **Real user queries**: production log'undan örnekleme

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Chunk size = sayfa | Embedding kalitesi düşer | ~500 token, semantic split |
| Metadata yok | Filtre + audit zor | Source + lifecycle + team |
| Plain similarity, hybrid yok | Kod/isim aramaları kaçar | BM25 + vector hybrid |
| Reranker atla | Top-K'da gürültü | Reranker (Cohere veya BGE) |
| Citation olmadan generation | Hallucination kontrolsüz | Source inline |
| Test set yok | Regression görünmez | Ragas + manual eval |
| PII chunk'larda | Veri sızıntısı | Ingestion'da filter |
| Ingestion big-bang (tüm wiki) | 6 ay önce update document de güncel sanılır | Incremental + freshness check |
| Embedding model değişti, re-index yok | Mismatch, retrieval kalitesiz | Embedding migration plan |
| Per-user access yok | Tüm kullanıcı her şey | Metadata + filtre |
| LLM cevaplarını cache yok | Tekrarlanan sorular pahalı | Semantic cache |
| Domain-specific tuning yok | Generic cevaplar | System prompt + few-shot |
| Türkçe için multilingual model değil | Embedding kalitesi düşük | BGE-M3 / multilingual-e5 |

---

## 📋 RAG Production Checklist

```
[ ] Document source listesi tanımlı (wiki, runbook, kod doc)
[ ] Chunking strategy (~500 token, semantic split)
[ ] Metadata enrichment (source, lifecycle, team)
[ ] Embedding model: multilingual (TR için BGE-M3)
[ ] Vector store: pgvector / Qdrant / Pinecone
[ ] Hybrid search (BM25 + vector)
[ ] Reranker (Cohere / BGE-Reranker)
[ ] Prompt: citation zorunlu + "bilmiyorum" izni
[ ] PII filtering ingestion'da
[ ] Per-user access control (metadata)
[ ] Incremental ingestion (yeni/güncel doc)
[ ] Eval set + Ragas metrikleri
[ ] Latency monitoring (p50/p99)
[ ] Cost tracking (embedding + LLM)
[ ] Hallucination rate monitoring
[ ] Output: source URL + section
[ ] Semantic cache (yaygın sorular)
[ ] Embedding model migration plan
[ ] AI Act high-risk değerlendirmesi (bkz Compliance)
```

---

## 📚 Referanslar

- **Anthropic Claude Docs** — docs.anthropic.com
- **LangChain RAG** — python.langchain.com/docs/use_cases/question_answering
- **LlamaIndex** — docs.llamaindex.ai
- **Haystack** — haystack.deepset.ai
- **pgvector** — github.com/pgvector/pgvector
- **Cohere Rerank** — docs.cohere.com/docs/reranking
- **BGE Embeddings** — huggingface.co/BAAI
- **Ragas (RAG eval)** — docs.ragas.io
- [`LLM-in-Production.md`](LLM-in-Production.md)
- [`Prompt-Engineering-for-Ops.md`](Prompt-Engineering-for-Ops.md)
- [`Safety-and-Guardrails.md`](Safety-and-Guardrails.md)
- [`19-Compliance/EU-AI-Act.md`](../19-Compliance/EU-AI-Act.md)

---

> *"RAG 'sihir' değil — **mühendislik disiplini**. Embedding + retrieve
> + rerank + cite + eval. Her aşama ölçülmeyen RAG, **halüsinasyon
> jeneratörüdür**."*
