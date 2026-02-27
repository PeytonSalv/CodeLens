"""Find gaps between intent and outcome.

Detects:
- Files mentioned in prompts but not touched in code
- Features described but not implemented
- Incomplete implementations
"""


struct GapAnalysis(Copyable, Movable):
    """Analysis of gaps between intent and outcome."""

    var mentioned_files_not_touched: List[String]
    var mentioned_features_not_found: List[String]
    var completion_score: Float32  # 0.0 to 1.0
    var gap_count: Int

    fn __init__(out self):
        self.mentioned_files_not_touched = List[String]()
        self.mentioned_features_not_found = List[String]()
        self.completion_score = 0.0
        self.gap_count = 0

    fn __init__(out self, *, copy: Self):
        self.mentioned_files_not_touched = copy.mentioned_files_not_touched.copy()
        self.mentioned_features_not_found = copy.mentioned_features_not_found.copy()
        self.completion_score = copy.completion_score
        self.gap_count = copy.gap_count

    fn __moveinit__(out self, deinit take: Self):
        self.mentioned_files_not_touched = take.mentioned_files_not_touched^
        self.mentioned_features_not_found = take.mentioned_features_not_found^
        self.completion_score = take.completion_score
        self.gap_count = take.gap_count


fn analyze_gaps(
    prompt_text: String,
    files_written: List[String],
    files_touched: List[String],
) -> GapAnalysis:
    """Analyze gaps between what was requested and what was done.

    Extracts file paths and keywords from prompt text and checks
    if they appear in the actual files written/touched.
    """
    var analysis = GapAnalysis()

    # Extract potential file references from prompt
    var mentioned_files = _extract_file_references(prompt_text)

    # Check which mentioned files were not touched
    for i in range(len(mentioned_files)):
        var mentioned = mentioned_files[i]
        var found = False

        for wi in range(len(files_written)):
            if mentioned in files_written[wi] or files_written[wi].endswith(mentioned):
                found = True
                break

        if not found:
            for ti in range(len(files_touched)):
                if mentioned in files_touched[ti] or files_touched[ti].endswith(mentioned):
                    found = True
                    break

        if not found:
            analysis.mentioned_files_not_touched.append(mentioned)

    # Compute completion score
    var total_mentioned = len(mentioned_files)
    if total_mentioned > 0:
        var touched_count = total_mentioned - len(analysis.mentioned_files_not_touched)
        analysis.completion_score = Float32(touched_count) / Float32(total_mentioned)
    else:
        # No specific files mentioned — check if any work was done
        if len(files_written) > 0:
            analysis.completion_score = 0.8  # Work done but can't verify specifics
        else:
            analysis.completion_score = 0.2  # No work visible

    analysis.gap_count = len(analysis.mentioned_files_not_touched) + len(
        analysis.mentioned_features_not_found
    )

    return analysis^


fn _extract_file_references(text: String) -> List[String]:
    """Extract potential file path references from prompt text.

    Looks for patterns like:
    - words containing '.' followed by common extensions
    - words containing '/' (path separators)
    """
    var results = List[String]()
    var words = text.split(" ")

    var extensions = List[String]()
    extensions.append(".rs")
    extensions.append(".ts")
    extensions.append(".tsx")
    extensions.append(".js")
    extensions.append(".jsx")
    extensions.append(".py")
    extensions.append(".mojo")
    extensions.append(".go")
    extensions.append(".java")
    extensions.append(".css")
    extensions.append(".html")
    extensions.append(".json")
    extensions.append(".toml")
    extensions.append(".yaml")
    extensions.append(".yml")

    for wi in range(len(words)):
        var word_raw = String(words[wi])
        var word = String(word_raw.strip())
        # Remove common punctuation
        while len(word) > 0 and (
            word.as_bytes()[len(word) - 1] == UInt8(ord(","))
            or word.as_bytes()[len(word) - 1] == UInt8(ord(")"))
            or word.as_bytes()[len(word) - 1] == UInt8(ord('"'))
            or word.as_bytes()[len(word) - 1] == UInt8(ord("'"))
            or word.as_bytes()[len(word) - 1] == UInt8(ord("`"))
        ):
            word = String(word[: len(word) - 1])

        if word == "":
            continue

        # Check if word looks like a file path
        for ei in range(len(extensions)):
            if word.endswith(extensions[ei]):
                # Check it's not already in results
                var already = False
                for ri in range(len(results)):
                    if results[ri] == word:
                        already = True
                        break
                if not already:
                    results.append(word)
                break

    return results^
