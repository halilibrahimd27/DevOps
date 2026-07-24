---
description: "RAG (Retrieval-Augmented Generation) architecture: building the embedding, vector store, retriever, reranker, and generation stages in production; giving the LLM an external source."
tags:
  - AI/LLMOps
  - Databases
  - PostgreSQL
  - Security
  - Performance
---
# RAG Architecture — Retrieval-Augmented Generation

> *"The **hallucination** an LLM produces while it's sure it 'knows
> everything' comes from not being able to answer 'where's this sentence
> from?' when looking at a company document. **RAG** = giving the LLM a library."*

This guide covers concrete ways to build Retrieval-Augmented Generation
architecture — embedding, vector store, retriever, reranker, generation —
in production.

---

## 🎯 What Is RAG?

> **RAG**: The LLM answering by pulling information not just from its
> training data but from an **external source**.

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
  "Answer using this context:
   {chunks}
   
   Question: {query}"
                            │
                            ▼
                       [LLM]
                            │
                            ▼
                    [Answer + citations]
```

---

## 📐 Components of RAG

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

## 🛠️ Tech Stack — Common Choices

| Component | Options |
|---|---|
| **Embedding model** | OpenAI `text-embedding-3-small`, BGE-M3, multilingual-e5 |
| **Vector store** | pgvector (Postgres ext), Pinecone, Weaviate, Qdrant, Milvus |
| **Retriever** | Plain similarity, hybrid (BM25 + vector) |
| **Reranker** | Cohere Rerank, BGE-Reranker, ColBERT |
| **LLM** | Claude / GPT-4 / Gemini / Llama (open-source) |
| **Framework** | LangChain, LlamaIndex, Haystack |
| **Orchestration** | Temporal / Airflow (batch ingestion) |

> 🔑 **For Turkish**: BGE-M3 multilingual + Claude / GPT-4 (excellent Turkish support).

---

## 📦 1️⃣ Document Ingestion

### Chunking strategy
```python
# Semantic chunking (recommended)
from langchain.text_splitter import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,           # tokens (~750 chars)
    chunk_overlap=50,         # context bridge
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

> 🔑 Metadata lets you **filter**: "only updated in the last 6 months + payments team".

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
-- Postgres: combine tsvector + pgvector
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

> 🔑 Hybrid search is ~20-30% better. Use BM25 for specific name/code searches, vector for semantic search.

---

## 🎯 3️⃣ Reranker (Optional but powerful)

Initial retrieval pulls 20 chunks → the reranker picks the 5 most relevant.

### Cohere Rerank
```python
import cohere

co = cohere.Client(<API_KEY>)

results = co.rerank(
    query="How does a credit card refund work?",
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
PROMPT = """You are a DevOps assistant. Answer the question using the context provided to you.

Rules:
1. Use ONLY the information in the context.
2. If the information isn't in the context, say "I don't have information on this."
3. Cite the source at the end of every answer [Source: filename, section].
4. Answer in Turkish.

Context:
{context}

Question: {question}

Answer:"""

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

### 1. **Hallucination control**
- Citation is mandatory — a source for every claim
- Give the prompt permission to say "I don't know"
- Source URL/path always in the output

### 2. **Latency**
- Embedding: ~50ms
- Vector search: ~10-100ms (HNSW)
- Reranker: ~200-500ms
- LLM: 1-5s
- **Total**: 2-6s

### 3. **Cost**
- Embedding: ~$0.02 / 1M tokens (OpenAI text-embedding-3-small; ≈ $0.00002/1K)
- Vector store: storage + index
- LLM: $1-15 / 1M tokens (depending on the model)

### 4. **Freshness**
- Document update → re-ingest
- Incremental: only the changed chunks
- Schedule: nightly cron + on-event webhook

### 5. **Security**
- PII filtering at ingestion
- Per-user access control: `allowed_groups` in metadata
- Vector store as a separate service (compromise blast radius)

---

## 🎯 Evaluation

### Metrics
| Metric | Description |
|---|---|
| **Retrieval@K** | Is there a relevant chunk in the top-K? |
| **MRR** (Mean Reciprocal Rank) | What rank does the relevant chunk land at? |
| **Faithfulness** | Is the LLM's answer consistent with the context? (hallucination measurement) |
| **Answer Relevance** | Does the answer address the question? |
| **Context Precision** | How much of the context is actually relevant? |

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
- **Manual curation**: 100-300 question-answer pairs
- **LLM-generated**: synthetic via GPT-4
- **Real user queries**: sampled from production logs

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Chunk size = a page | Embedding quality drops | ~500 tokens, semantic split |
| No metadata | Filtering + audit is hard | Source + lifecycle + team |
| Plain similarity, no hybrid | Code/name searches get missed | BM25 + vector hybrid |
| Skip the reranker | Noise in the top-K | Reranker (Cohere or BGE) |
| Generation without citation | Hallucination goes unchecked | Inline source |
| No test set | Regression stays invisible | Ragas + manual eval |
| PII in chunks | Data leak | Filter at ingestion |
| Big-bang ingestion (whole wiki) | A doc updated 6 months ago is assumed fresh | Incremental + freshness check |
| Embedding model changed, no re-index | Mismatch, poor retrieval quality | Embedding migration plan |
| No per-user access | Every user sees everything | Metadata + filter |
| No cache for LLM answers | Repeated questions are expensive | Semantic cache |
| No domain-specific tuning | Generic answers | System prompt + few-shot |
| Non-multilingual model for Turkish | Poor embedding quality | BGE-M3 / multilingual-e5 |

---

## 📋 RAG Production Checklist

```
[ ] Document source list defined (wiki, runbook, code doc)
[ ] Chunking strategy (~500 tokens, semantic split)
[ ] Metadata enrichment (source, lifecycle, team)
[ ] Embedding model: multilingual (BGE-M3 for TR)
[ ] Vector store: pgvector / Qdrant / Pinecone
[ ] Hybrid search (BM25 + vector)
[ ] Reranker (Cohere / BGE-Reranker)
[ ] Prompt: citation mandatory + "I don't know" permission
[ ] PII filtering at ingestion
[ ] Per-user access control (metadata)
[ ] Incremental ingestion (new/updated docs)
[ ] Eval set + Ragas metrics
[ ] Latency monitoring (p50/p99)
[ ] Cost tracking (embedding + LLM)
[ ] Hallucination rate monitoring
[ ] Output: source URL + section
[ ] Semantic cache (frequent queries)
[ ] Embedding model migration plan
[ ] AI Act high-risk assessment (see Compliance)
```

---

## 📚 References

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

> *"RAG isn't 'magic' — it's **engineering discipline**. Embedding + retrieve
> + rerank + cite + eval. A RAG whose every stage goes unmeasured is a
> **hallucination generator**."*
