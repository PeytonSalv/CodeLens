"""DBSCAN clustering on embedding vectors to group commits into semantic features.

Replaces the 4-hour time-window heuristic with semantic similarity-based clustering.
Uses cosine distance between 768-dim CodeBERT embeddings.
"""

from math import sqrt
from .types import CommitData, FeatureCluster
from .embeddings import EmbeddingResult, EMBEDDING_DIM
from .git_parser import build_feature


comptime NOISE_LABEL: Int = -1


fn cosine_similarity(a: List[Float32], b: List[Float32]) -> Float32:
    """Compute cosine similarity between two vectors."""
    if len(a) != len(b) or len(a) == 0:
        return 0.0

    var dot: Float32 = 0.0
    var norm_a: Float32 = 0.0
    var norm_b: Float32 = 0.0

    for i in range(len(a)):
        dot += a[i] * b[i]
        norm_a += a[i] * a[i]
        norm_b += b[i] * b[i]

    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0

    return dot / (sqrt(norm_a) * sqrt(norm_b))


fn cosine_distance(a: List[Float32], b: List[Float32]) -> Float32:
    """Compute cosine distance (1 - cosine_similarity)."""
    return 1.0 - cosine_similarity(a, b)


fn build_distance_matrix(
    embeddings: List[EmbeddingResult],
) -> List[List[Float32]]:
    """Build a symmetric distance matrix from embeddings using cosine distance."""
    var n = len(embeddings)
    var matrix = List[List[Float32]]()

    for i in range(n):
        var row = List[Float32]()
        for j in range(n):
            if i == j:
                row.append(0.0)
            elif j < i:
                # Copy from symmetric position
                row.append(matrix[j][i])
            else:
                row.append(
                    cosine_distance(embeddings[i].vector, embeddings[j].vector)
                )
        matrix.append(row^)

    return matrix^


fn dbscan(
    distance_matrix: List[List[Float32]],
    eps: Float32 = 0.3,
    min_samples: Int = 2,
) -> List[Int]:
    """DBSCAN clustering algorithm on a precomputed distance matrix.

    Args:
        distance_matrix: Symmetric N×N distance matrix.
        eps: Maximum distance between two samples to be considered neighbors.
        min_samples: Minimum number of samples in a neighborhood for a core point.

    Returns:
        List of cluster labels (0-indexed). -1 = noise.
    """
    var n = len(distance_matrix)
    var labels = List[Int]()
    for _ in range(n):
        labels.append(-2)  # -2 = undefined

    var cluster_id: Int = 0

    for i in range(n):
        if labels[i] != -2:
            continue

        # Find neighbors
        var neighbors = range_query(distance_matrix, i, eps)

        if len(neighbors) < min_samples:
            labels[i] = NOISE_LABEL
            continue

        # Start new cluster
        labels[i] = cluster_id

        # Seed set (excluding i itself)
        var seed_set = List[Int]()
        for ni in range(len(neighbors)):
            if neighbors[ni] != i:
                seed_set.append(neighbors[ni])

        var si = 0
        while si < len(seed_set):
            var q = seed_set[si]

            if labels[q] == NOISE_LABEL:
                labels[q] = cluster_id
            elif labels[q] != -2:
                si += 1
                continue
            else:
                labels[q] = cluster_id

            var q_neighbors = range_query(distance_matrix, q, eps)

            if len(q_neighbors) >= min_samples:
                for qni in range(len(q_neighbors)):
                    var qn = q_neighbors[qni]
                    # Add to seed set if not already processed
                    var already_in = False
                    for ssi in range(len(seed_set)):
                        if seed_set[ssi] == qn:
                            already_in = True
                            break
                    if not already_in and qn != i:
                        seed_set.append(qn)

            si += 1

        cluster_id += 1

    return labels^


fn range_query(
    distance_matrix: List[List[Float32]], point: Int, eps: Float32
) -> List[Int]:
    """Find all points within eps distance of the given point."""
    var neighbors = List[Int]()
    for i in range(len(distance_matrix[point])):
        if distance_matrix[point][i] <= eps:
            neighbors.append(i)
    return neighbors^


fn cluster_commits_semantic(
    mut commits: List[CommitData],
    embeddings: List[EmbeddingResult],
    eps: Float32 = 0.3,
    min_samples: Int = 2,
) -> List[FeatureCluster]:
    """Cluster commits using DBSCAN on CodeBERT embeddings.

    Replaces the time-window heuristic with semantic similarity clustering.
    Commits not covered by embeddings are assigned to noise cluster.
    """
    if len(embeddings) == 0:
        return List[FeatureCluster]()

    # Build hash→index mapping for embeddings
    var emb_hashes = List[String]()
    for i in range(len(embeddings)):
        emb_hashes.append(embeddings[i].commit_hash)

    # Build distance matrix
    var dist_matrix = build_distance_matrix(embeddings)

    # Run DBSCAN
    var labels = dbscan(dist_matrix, eps, min_samples)

    # Find max cluster label
    var max_label: Int = -1
    for i in range(len(labels)):
        if labels[i] > max_label:
            max_label = labels[i]

    # Group commits by cluster label
    var features = List[FeatureCluster]()

    for cluster_label in range(max_label + 1):
        var cluster_indices = List[Int]()

        for ei in range(len(labels)):
            if labels[ei] != cluster_label:
                continue

            var emb_hash = emb_hashes[ei]

            # Find this commit in the commits list
            for ci in range(len(commits)):
                if commits[ci].hash == emb_hash:
                    cluster_indices.append(ci)
                    break

        if len(cluster_indices) > 0:
            var feature = build_feature(
                Int32(cluster_label), cluster_indices, commits
            )
            for idx in range(len(cluster_indices)):
                commits[cluster_indices[idx]].cluster_id = Int32(cluster_label)
            features.append(feature^)

    # Handle noise points — assign each to its own cluster or merge with nearest
    var noise_cluster_id = Int32(max_label + 1)
    for ei in range(len(labels)):
        if labels[ei] != NOISE_LABEL:
            continue

        var emb_hash = emb_hashes[ei]
        for ci in range(len(commits)):
            if commits[ci].hash == emb_hash:
                commits[ci].cluster_id = noise_cluster_id
                var single = List[Int]()
                single.append(ci)
                features.append(
                    build_feature(noise_cluster_id, single, commits)
                )
                noise_cluster_id += 1
                break

    return features^
