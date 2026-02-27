"""Cosine similarity between prompt embeddings and commit diff embeddings.

Implements the new correlation formula:
  0.4 x cosine_similarity(prompt_embedding, diff_embedding)
  + 0.3 x file_overlap
  + 0.2 x timestamp_overlap
  + 0.1 x co_author_marker
"""

from .clustering import cosine_similarity


struct CorrelationScore(Copyable, Movable):
    """Correlation score between a prompt and a commit."""

    var prompt_index: Int
    var commit_hash: String
    var total_score: Float32
    var semantic_score: Float32
    var file_score: Float32
    var time_score: Float32
    var marker_score: Float32

    fn __init__(out self):
        self.prompt_index = 0
        self.commit_hash = String("")
        self.total_score = 0.0
        self.semantic_score = 0.0
        self.file_score = 0.0
        self.time_score = 0.0
        self.marker_score = 0.0

    fn __init__(out self, *, copy: Self):
        self.prompt_index = copy.prompt_index
        self.commit_hash = copy.commit_hash
        self.total_score = copy.total_score
        self.semantic_score = copy.semantic_score
        self.file_score = copy.file_score
        self.time_score = copy.time_score
        self.marker_score = copy.marker_score

    fn __moveinit__(out self, deinit take: Self):
        self.prompt_index = take.prompt_index
        self.commit_hash = take.commit_hash^
        self.total_score = take.total_score
        self.semantic_score = take.semantic_score
        self.file_score = take.file_score
        self.time_score = take.time_score
        self.marker_score = take.marker_score


fn compute_correlation_matrix(
    prompt_embeddings: List[List[Float32]],
    commit_embeddings: List[List[Float32]],
    commit_hashes: List[String],
    prompt_files: List[List[String]],
    commit_files: List[List[String]],
    prompt_timestamps: List[Int],
    commit_timestamps: List[Int],
    prompt_end_timestamps: List[Int],
    is_claude_code: List[Bool],
    threshold: Float32 = 0.5,
) -> List[CorrelationScore]:
    """Compute prompt-to-commit correlation scores.

    Uses weighted combination:
      0.4 x cosine_similarity(prompt_embedding, diff_embedding)
      + 0.3 x file_overlap_fraction
      + 0.2 x timestamp_overlap (1.0 if in window, 0.0 otherwise)
      + 0.1 x co_author_marker (1.0 if claude, 0.0 otherwise)

    Returns scores above the threshold.
    """
    var results = List[CorrelationScore]()

    var five_min: Int = 5 * 60

    for pi in range(len(prompt_embeddings)):
        for ci in range(len(commit_embeddings)):
            # Semantic similarity
            var semantic = cosine_similarity(
                prompt_embeddings[pi], commit_embeddings[ci]
            )

            # File overlap: compare basenames
            var file_overlap: Float32 = 0.0
            if len(commit_files[ci]) > 0:
                var overlap_count: Int = 0
                for pf in range(len(prompt_files[pi])):
                    var p_basename = _basename(prompt_files[pi][pf])
                    for cf in range(len(commit_files[ci])):
                        var c_basename = _basename(commit_files[ci][cf])
                        if p_basename == c_basename:
                            overlap_count += 1
                            break
                file_overlap = Float32(overlap_count) / Float32(
                    len(commit_files[ci])
                )

            # Timestamp overlap
            var time_overlap: Float32 = 0.0
            var commit_ts = commit_timestamps[ci]
            var prompt_start = prompt_timestamps[pi]
            var prompt_end = prompt_end_timestamps[pi]
            if prompt_end == 0:
                prompt_end = prompt_start

            if commit_ts >= prompt_start and commit_ts <= prompt_end + five_min:
                time_overlap = 1.0

            # Claude marker
            var marker: Float32 = 0.0
            if is_claude_code[ci]:
                marker = 1.0

            # Weighted total
            var total = (
                0.4 * semantic
                + 0.3 * file_overlap
                + 0.2 * time_overlap
                + 0.1 * marker
            )

            if total >= threshold:
                var score = CorrelationScore()
                score.prompt_index = pi
                score.commit_hash = commit_hashes[ci]
                score.total_score = total
                score.semantic_score = semantic
                score.file_score = file_overlap
                score.time_score = time_overlap
                score.marker_score = marker
                results.append(score^)

    return results^


fn _basename(path: String) -> String:
    """Extract filename from a path."""
    var last_slash = -1
    for i in range(len(path)):
        if path.as_bytes()[i] == UInt8(ord("/")) or path.as_bytes()[i] == UInt8(ord("\\")):
            last_slash = i
    if last_slash >= 0 and last_slash < len(path) - 1:
        return String(path[last_slash + 1 :])
    return path
