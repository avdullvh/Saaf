"""
accounts/recommendations.py

LightGCN-based user recommendation system.
Uses Graph Neural Networks to learn user embeddings from the social follow graph,
then ranks candidates by dot-product similarity.

Temperature-based sampling ensures recommendations vary on each page refresh
while still favouring higher-scored (more relevant) users.

Reference: He et al., "LightGCN: Simplifying and Powering Graph Convolution
           Network for Recommendation" (SIGIR 2020)
"""

import threading
import logging

import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim

from .models import User, Follow

logger = logging.getLogger(__name__)


# ──────────────────────────────────────────────────────────────────────────────
# 1.  Model definition
# ──────────────────────────────────────────────────────────────────────────────

class LightGCN(nn.Module):
    """
    Lightweight Graph Convolution Network for collaborative filtering.

    Each user is represented by a learnable embedding vector. Those vectors
    are propagated through the follow-graph for `num_layers` hops and then
    averaged across all layers to produce the final representation.
    """

    def __init__(self, num_users: int, embedding_dim: int = 64, num_layers: int = 3):
        super().__init__()
        self.num_layers = num_layers
        self.embedding = nn.Embedding(num_users, embedding_dim)
        nn.init.xavier_uniform_(self.embedding.weight)

    def forward(self, adj: torch.Tensor) -> torch.Tensor:
        """
        Propagate embeddings through the graph.

        Args:
            adj: Normalised symmetric sparse adjacency matrix  (N × N)

        Returns:
            Final user embeddings  (N × D)  — mean of all layers.
        """
        x = self.embedding.weight          # [N, D]
        layers = [x]

        for _ in range(self.num_layers):
            x = torch.sparse.mm(adj, x)
            layers.append(x)

        return torch.stack(layers, dim=0).mean(dim=0)   # mean-pool

    def bpr_loss(
        self,
        embeddings: torch.Tensor,
        pos_pairs: torch.Tensor,
        neg_pairs: torch.Tensor,
    ) -> torch.Tensor:
        """
        Bayesian Personalised Ranking loss with L2 regularisation.

        pos_pairs: (B, 2) tensor of (user_idx, followed_idx)
        neg_pairs: (B, 2) tensor of (user_idx, random_idx)
        """
        u  = embeddings[pos_pairs[:, 0]]
        pi = embeddings[pos_pairs[:, 1]]
        ni = embeddings[neg_pairs[:, 1]]

        pos_scores = (u * pi).sum(dim=1)
        neg_scores = (u * ni).sum(dim=1)

        bpr  = -torch.log(torch.sigmoid(pos_scores - neg_scores) + 1e-8).mean()
        reg  = (u.norm(2).pow(2) + pi.norm(2).pow(2) + ni.norm(2).pow(2)) / (2 * len(pos_pairs))

        return bpr + 1e-4 * reg


# ──────────────────────────────────────────────────────────────────────────────
# 2.  Shared in-memory state (singleton)
# ──────────────────────────────────────────────────────────────────────────────

class RecommenderState:
    """
    Thread-safe singleton that holds the trained model and cached embeddings.
    All request handlers read from this object without hitting the GPU/DB.
    """

    _instance = None
    _lock = threading.Lock()

    def __init__(self):
        self.embeddings: torch.Tensor | None = None   # [N, D] float tensor
        self.user_id_to_idx: dict[int, int] = {}
        self.idx_to_user_id: dict[int, int] = {}
        self.adj: torch.Tensor | None = None
        self.is_trained: bool = False
        self.training_lock = threading.Lock()

    @classmethod
    def get(cls) -> "RecommenderState":
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = cls()
        return cls._instance


# ──────────────────────────────────────────────────────────────────────────────
# 3.  Graph construction
# ──────────────────────────────────────────────────────────────────────────────

def _build_adj_matrix(
    follow_pairs: list[tuple[int, int]],
    num_users: int,
) -> torch.Tensor:
    """
    Build a D^{-1/2} A D^{-1/2} normalised symmetric adjacency matrix.
    Edges are made bidirectional and self-loops are added for stability.
    Returns a sparse COO FloatTensor.
    """
    rows, cols = [], []

    for u, v in follow_pairs:
        rows += [u, v]      # bidirectional
        cols += [v, u]

    for i in range(num_users):  # self-loops
        rows.append(i)
        cols.append(i)

    idx    = torch.tensor([rows, cols], dtype=torch.long)
    vals   = torch.ones(len(rows), dtype=torch.float)
    adj    = torch.sparse_coo_tensor(idx, vals, (num_users, num_users)).coalesce()

    degree = torch.sparse.sum(adj, dim=1).to_dense()
    d_inv  = torch.where(degree > 0, degree.pow(-0.5), torch.zeros_like(degree))

    norm_vals = d_inv[idx[0]] * vals * d_inv[idx[1]]
    return torch.sparse_coo_tensor(idx, norm_vals, (num_users, num_users)).coalesce()


# ──────────────────────────────────────────────────────────────────────────────
# 4.  Training
# ──────────────────────────────────────────────────────────────────────────────

def train_recommender(
    epochs: int = 150,
    lr: float = 0.01,
    embedding_dim: int = 64,
    num_layers: int = 3,
) -> None:
    """
    Train LightGCN on the current social graph from the database.
    Called in a background thread on server startup (and via the retrain endpoint).
    """
    state = RecommenderState.get()

    with state.training_lock:
        logger.info("[Recommender] Starting LightGCN training…")

        user_ids  = list(User.objects.values_list('id', flat=True))
        follow_db = list(Follow.objects.values_list('follower_id', 'following_id'))

        if len(user_ids) < 2:
            logger.warning("[Recommender] Not enough users — skipping training.")
            return

        id_to_idx = {uid: i for i, uid in enumerate(user_ids)}
        idx_to_id = {i: uid for uid, i in id_to_idx.items()}
        N         = len(user_ids)

        pairs = [
            (id_to_idx[f], id_to_idx[t])
            for f, t in follow_db
            if f in id_to_idx and t in id_to_idx
        ]

        # Store mappings even if no edges yet (cold-start)
        state.user_id_to_idx = id_to_idx
        state.idx_to_user_id = idx_to_id

        if not pairs:
            logger.warning("[Recommender] No follow relationships — model will use random fallback.")
            state.is_trained = False
            return

        adj   = _build_adj_matrix(pairs, N)
        model = LightGCN(N, embedding_dim=embedding_dim, num_layers=num_layers)
        opt   = optim.Adam(model.parameters(), lr=lr)
        pt    = torch.tensor(pairs, dtype=torch.long)

        model.train()
        for epoch in range(epochs):
            opt.zero_grad()
            emb = model(adj)

            neg_idx = torch.randint(0, N, (len(pairs),))
            neg_pt  = torch.stack([pt[:, 0], neg_idx], dim=1)

            loss = model.bpr_loss(emb, pt, neg_pt)
            loss.backward()
            opt.step()

            if (epoch + 1) % 50 == 0:
                logger.info(f"[Recommender] Epoch {epoch + 1}/{epochs}  loss={loss.item():.4f}")

        model.eval()
        with torch.no_grad():
            final_emb = model(adj).detach()

        state.embeddings = final_emb
        state.adj        = adj
        state.is_trained = True

        logger.info(
            f"[Recommender] Training complete — {N} users, {len(pairs)} edges."
        )


# ──────────────────────────────────────────────────────────────────────────────
# 5.  Inference (with refresh variety via temperature sampling)
# ──────────────────────────────────────────────────────────────────────────────

def get_ml_recommendations(
    user,
    limit: int = 10,
    diversity: float = 0.4,
) -> list:
    """
    Return recommended users using LightGCN dot-product similarity.

    Args:
        user:      The requesting User object.
        limit:     Maximum number of recommendations to return.
        diversity: Float in [0, 1].
                   • 0.0 → strict top-K (same every refresh)
                   • 0.4 → weighted sampling from a top-pool (varies each refresh
                            while still favouring better matches — DEFAULT)
                   • 1.0 → nearly random

    The scoring is deterministic (same trained model), but *which* users from
    the high-scoring pool are returned changes on every request, giving the
    "different results on refresh" experience the user wants.
    """
    state = RecommenderState.get()

    already_following = set(
        Follow.objects.filter(follower=user).values_list('following_id', flat=True)
    )
    exclude = already_following | {user.id}

    # ── Cold start / untrained fallback ──────────────────────────────────────
    if not state.is_trained or user.id not in state.user_id_to_idx:
        logger.info(f"[Recommender] Cold-start for user {user.id} — random fallback.")
        return list(User.objects.exclude(id__in=exclude).order_by('?')[:limit])

    # ── Scoring ───────────────────────────────────────────────────────────────
    u_idx    = state.user_id_to_idx[user.id]
    u_emb    = state.embeddings[u_idx]                     # [D]
    scores   = torch.matmul(state.embeddings, u_emb).numpy()  # [N]

    candidates = [
        (state.idx_to_user_id[i], float(scores[i]))
        for i in range(len(scores))
        if state.idx_to_user_id[i] not in exclude
    ]

    if not candidates:
        return list(User.objects.exclude(id__in=exclude).order_by('?')[:limit])

    candidates.sort(key=lambda x: x[1], reverse=True)

    # ── Diversity / refresh variety ───────────────────────────────────────────
    # Sample from the top-pool using softmax-weighted probabilities.
    # Temperature controls how "peaky" the distribution is:
    #   low temp  → near-deterministic top-K
    #   high temp → more uniform (varied)
    pool_size = min(len(candidates), max(limit * 4, 30))
    pool      = candidates[:pool_size]

    if diversity > 0 and len(pool) > limit:
        raw     = np.array([c[1] for c in pool], dtype=np.float64)
        temp    = max(0.05, diversity * 2.5)            # temperature
        raw     = raw / temp
        raw    -= raw.max()                             # numerical stability
        weights = np.exp(raw)
        weights /= weights.sum()

        chosen = np.random.choice(
            len(pool),
            size=min(limit, len(pool)),
            replace=False,
            p=weights,
        )
        top_ids = [pool[i][0] for i in chosen]
    else:
        top_ids = [c[0] for c in pool[:limit]]

    users     = User.objects.filter(id__in=top_ids)
    user_dict = {u.id: u for u in users}
    result    = [user_dict[uid] for uid in top_ids if uid in user_dict]

    # ── Backfill ──────────────────────────────────────────────────────────────
    if len(result) < limit:
        bf_exclude = exclude | set(top_ids)
        needed     = limit - len(result)
        result.extend(
            User.objects.exclude(id__in=bf_exclude).order_by('?')[:needed]
        )

    return result
