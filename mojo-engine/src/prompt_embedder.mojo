"""Embed Claude Code prompt text using CodeBERT (same model as commit diffs).

Used for semantic prompt-to-code correlation in Phase 4.
"""

from .embeddings import EmbeddingEngine, EMBEDDING_DIM


struct PromptEmbedding(Copyable, Movable):
    """A single prompt embedding with metadata."""

    var prompt_index: Int
    var session_id: String
    var vector: List[Float32]
    var prompt_preview: String

    fn __init__(out self):
        self.prompt_index = 0
        self.session_id = String("")
        self.vector = List[Float32]()
        self.prompt_preview = String("")

    fn __init__(out self, *, copy: Self):
        self.prompt_index = copy.prompt_index
        self.session_id = copy.session_id
        self.vector = copy.vector.copy()
        self.prompt_preview = copy.prompt_preview

    fn __moveinit__(out self, deinit take: Self):
        self.prompt_index = take.prompt_index
        self.session_id = take.session_id^
        self.vector = take.vector^
        self.prompt_preview = take.prompt_preview^


fn embed_prompts(
    engine: EmbeddingEngine,
    prompt_texts: List[String],
    session_ids: List[String],
) raises -> List[PromptEmbedding]:
    """Embed a list of prompt texts using CodeBERT via the embedding engine.

    Returns empty list if engine is not loaded.
    """
    if not engine.model_loaded:
        return List[PromptEmbedding]()

    var results = List[PromptEmbedding]()

    for i in range(len(prompt_texts)):
        var text = prompt_texts[i]
        var vector = engine.embed_text(text)

        if len(vector) == EMBEDDING_DIM:
            var pe = PromptEmbedding()
            pe.prompt_index = i
            if i < len(session_ids):
                pe.session_id = session_ids[i]
            pe.vector = vector^
            if len(text) > 100:
                pe.prompt_preview = String(text[:100])
            else:
                pe.prompt_preview = text
            results.append(pe^)

    return results^
