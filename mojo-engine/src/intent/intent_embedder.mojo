"""Embed the "intent" of a prompt (what user wanted) vs the "outcome" (what code changed).

Computes semantic similarity between intent and outcome to measure completion.
"""

from ..clustering import cosine_similarity
from ..embeddings import EmbeddingEngine


fn compute_intent_outcome_similarity(
    intent_embedding: List[Float32],
    outcome_embedding: List[Float32],
) -> Float32:
    """Compute similarity between what was intended and what was produced.

    Higher score = closer match between intent and outcome.
    """
    return cosine_similarity(intent_embedding, outcome_embedding)


fn build_outcome_text(files_written: List[String], commit_subjects: List[String]) -> String:
    """Build a text representation of the outcome for embedding.

    Combines file paths and commit subjects into a single text string.
    """
    var text = String("")
    for i in range(len(files_written)):
        text += files_written[i] + "\n"
    for i in range(len(commit_subjects)):
        text += commit_subjects[i] + "\n"
    return text^
