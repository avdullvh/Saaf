# ML Social Network Recommendation Algorithm (SAAF)

This document explains the recommendation algorithm used in the SAAF social app:

- **What it is**
- **How it works (training + inference)**
- **A clear kNN-style worked example**

---

## 1) What Is This Algorithm?

SAAF uses a **LightGCN-based user recommendation system** for "Who to follow" suggestions.

In simple words:
- Every user is represented by a numeric vector (embedding).
- The model learns these vectors from the follow graph (who follows whom).
- Users with similar vectors are considered more relevant to each other.
- Recommendations are produced by ranking candidates using vector similarity.

The implementation is in:
- `saaf_backend/accounts/recommendations.py`

---

## 2) Why LightGCN for a Social App?

LightGCN is a graph-based recommender model that is strong for user-user or user-item relationship data.

For a social network:
- Nodes = users
- Edges = follow relationships
- Goal = recommend new users to follow

Compared with a rule-only system, LightGCN can learn hidden patterns such as:
- shared communities
- indirect relationships (friends of friends)
- global structure of the network

---

## 3) How It Works in SAAF

### A. Build the graph

From DB data:
- Users are loaded from `User`
- Follow edges are loaded from `Follow`

Then the system:
- makes edges bidirectional for graph propagation
- adds self-loops (each user connected to self)
- builds normalized adjacency matrix: **D^(-1/2) A D^(-1/2)**

This normalization keeps propagation stable and prevents high-degree nodes from dominating.

### B. Learn user embeddings (LightGCN forward pass)

Each user starts with a trainable embedding (size `64` by default).  
Embeddings are propagated through the graph for `3` layers by default:

- Layer 0: initial embeddings
- Layer 1..L: neighborhood-aggregated embeddings via sparse matrix multiply
- Final embedding = mean of all layer embeddings

This lets each user vector include:
- own profile position in graph
- nearby community information
- multi-hop social signals

### C. Train with BPR loss

Training uses **Bayesian Personalized Ranking (BPR)**:
- Positive pair: `(user, actually-followed-user)`
- Negative pair: `(user, random-user-not-followed)`

The loss pushes:
- positive score higher than negative score

In code this is based on dot products:
- `score(u, v) = emb(u) dot emb(v)`

So training objective is:  
for each user, real follow edges should rank above random non-follow edges.

### D. Serve recommendations

At request time (`/api/profile/recommendations/`):

1. Exclude:
   - current user
   - already-followed users
2. Score each remaining candidate by dot product with requester embedding
3. Sort by score descending
4. Apply diversity sampling from a top pool (temperature-softmax)
5. Return up to 10 users

### E. Cold-start fallback

If model is not trained yet, or user has no embedding:
- system returns random users (excluding self + already-followed)

---

## 4) Example (Step by Step)


### Setup

Assume users: **A, B, C, D, E, F**

Follow graph (directed in app data):
- A follows B, C
- B follows C, D
- C follows D
- E follows F

After LightGCN training, suppose embeddings become:

- A = `[0.90, 0.80]`
- B = `[0.85, 0.75]`
- C = `[0.88, 0.82]`
- D = `[0.80, 0.78]`
- E = `[0.10, 0.20]`
- F = `[0.12, 0.18]`

Assume user **A** requests recommendations.

Already followed by A: `{B, C}`  
Excluded set: `{A, B, C}`

Candidates: `D, E, F`

### Step 1: Compute similarity scores (dot product)

`score(A, X) = A dot X`

- score(A, D) = `0.90*0.80 + 0.80*0.78 = 0.72 + 0.624 = 1.344`
- score(A, E) = `0.90*0.10 + 0.80*0.20 = 0.09 + 0.16 = 0.25`
- score(A, F) = `0.90*0.12 + 0.80*0.18 = 0.108 + 0.144 = 0.252`

### Step 2: Rank candidates (kNN-like ranking)

Descending by score:
1. D (`1.344`)
2. F (`0.252`)
3. E (`0.250`)

Without diversity, top result is clearly **D**.

### Step 3: Diversity sampling behavior

SAAF adds controlled variety using temperature-weighted sampling from top candidates:

- High score users (like D) still have the largest probability.
- Lower score users (E/F) can occasionally appear, so refresh is not identical every time.

This is why users see:
- mostly relevant recommendations
- but not the exact same list on every refresh


SAAF recommendation does the same ranking idea, but on **learned graph embeddings** (not raw feature vectors), which usually captures social structure better.

---


## 6) One-Line Summary

SAAF uses **LightGCN + BPR ranking** to learn user similarity from the follow graph, then returns follow suggestions by score with a diversity mechanism so recommendations remain both relevant and fresh.
