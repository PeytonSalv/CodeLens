"""Classify prompt outcome: completed, partial, abandoned, reworked.

Uses heuristics based on:
- Whether files were actually written after the prompt
- Whether there was a re-prompt on the same topic
- Whether the session continued with different work
"""


struct OutcomeClassification(Copyable, Movable):
    """Classification of a prompt's outcome."""

    var outcome: String  # "completed", "partial", "abandoned", "reworked"
    var confidence: Float32
    var reason: String

    fn __init__(out self):
        self.outcome = String("completed")
        self.confidence = 0.5
        self.reason = String("")

    fn __init__(out self, *, copy: Self):
        self.outcome = copy.outcome
        self.confidence = copy.confidence
        self.reason = copy.reason

    fn __moveinit__(out self, deinit take: Self):
        self.outcome = take.outcome^
        self.confidence = take.confidence
        self.reason = take.reason^


fn classify_outcome(
    prompt_index: Int,
    total_prompts: Int,
    files_written_count: Int,
    tool_call_count: Int,
    was_reprompted: Bool,
    had_file_edits: Bool,
) -> OutcomeClassification:
    """Classify the outcome of a single prompt.

    Heuristics:
    - completed: files were written and no re-prompt detected
    - partial: some files written but was re-prompted (topic continued)
    - abandoned: no files written, no tool calls
    - reworked: files were written but then re-prompted (corrections needed)
    """
    var result = OutcomeClassification()

    if files_written_count == 0 and tool_call_count == 0:
        result.outcome = "abandoned"
        result.confidence = 0.8
        result.reason = "No tool calls or file writes detected"
        return result^

    if files_written_count == 0 and tool_call_count > 0:
        # Tool calls but no writes — probably research/exploration
        if was_reprompted:
            result.outcome = "abandoned"
            result.confidence = 0.6
            result.reason = "Tool calls but no writes, followed by re-prompt"
        else:
            result.outcome = "partial"
            result.confidence = 0.5
            result.reason = "Tool calls but no file writes"
        return result^

    if had_file_edits and was_reprompted:
        result.outcome = "reworked"
        result.confidence = 0.75
        result.reason = "Files edited but user re-prompted on same topic"
        return result^

    if had_file_edits and not was_reprompted:
        result.outcome = "completed"
        result.confidence = 0.85
        result.reason = "Files edited, no re-prompt detected"
        return result^

    # Default
    result.outcome = "partial"
    result.confidence = 0.5
    result.reason = "Ambiguous outcome"
    return result^
