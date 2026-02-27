"""Detect when user re-prompted on same topic.

A re-prompt is detected when semantic similarity > 0.85 between consecutive
user prompts within the same session.
"""

from ..clustering import cosine_similarity
from ..embeddings import EmbeddingEngine


comptime REPROMPT_THRESHOLD: Float32 = 0.85


struct RepromptEvent(Copyable, Movable):
    """A detected re-prompt pair."""

    var original_index: Int
    var repeat_index: Int
    var similarity: Float32
    var original_text: String
    var repeat_text: String

    fn __init__(out self):
        self.original_index = 0
        self.repeat_index = 0
        self.similarity = 0.0
        self.original_text = String("")
        self.repeat_text = String("")

    fn __init__(out self, *, copy: Self):
        self.original_index = copy.original_index
        self.repeat_index = copy.repeat_index
        self.similarity = copy.similarity
        self.original_text = copy.original_text
        self.repeat_text = copy.repeat_text

    fn __moveinit__(out self, deinit take: Self):
        self.original_index = take.original_index
        self.repeat_index = take.repeat_index
        self.similarity = take.similarity
        self.original_text = take.original_text^
        self.repeat_text = take.repeat_text^


fn detect_reprompts(
    prompt_texts: List[String],
    prompt_embeddings: List[List[Float32]],
    threshold: Float32 = REPROMPT_THRESHOLD,
) -> List[RepromptEvent]:
    """Detect re-prompts by checking semantic similarity between consecutive prompts.

    Returns a list of RepromptEvent for each detected re-prompt pair.
    """
    var results = List[RepromptEvent]()

    if len(prompt_embeddings) < 2:
        return results^

    for i in range(1, len(prompt_embeddings)):
        var sim = cosine_similarity(prompt_embeddings[i - 1], prompt_embeddings[i])

        if sim >= threshold:
            var event = RepromptEvent()
            event.original_index = i - 1
            event.repeat_index = i
            event.similarity = sim
            if i - 1 < len(prompt_texts):
                var text = prompt_texts[i - 1]
                if len(text) > 120:
                    event.original_text = String(text[:120])
                else:
                    event.original_text = text
            if i < len(prompt_texts):
                var text = prompt_texts[i]
                if len(text) > 120:
                    event.repeat_text = String(text[:120])
                else:
                    event.repeat_text = text
            results.append(event^)

    return results^


fn count_reprompts_for_session(reprompts: List[RepromptEvent]) -> Int:
    """Count total re-prompts in a session."""
    return len(reprompts)
