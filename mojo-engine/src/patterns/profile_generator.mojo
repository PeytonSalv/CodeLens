"""Generate developer profile aggregating all detected patterns.

Produces a DeveloperProfile struct and optionally a claude_context.md file.
"""

from ..types import CommitData, FeatureCluster
from ..types.commit import _json_str, _json_f32
from ..git_parser import detect_languages
from .temporal_tracker import TemporalPattern
from .pattern_detector import FileCouple, compute_commit_granularity


struct DeveloperProfile(Copyable, Movable):
    """Aggregated developer behavior profile."""

    var preferred_languages: List[String]
    var avg_session_length_mins: Float32
    var reprompt_rate: Float32
    var tool_call_frequency: Float32
    var common_change_types: List[String]  # type keys
    var common_change_counts: List[UInt32]  # type values
    var peak_hours: List[Int]
    var avg_commit_granularity: Float32
    var file_couplings: List[FileCouple]
    var total_sessions: Int
    var total_prompts: Int

    fn __init__(out self):
        self.preferred_languages = List[String]()
        self.avg_session_length_mins = 0.0
        self.reprompt_rate = 0.0
        self.tool_call_frequency = 0.0
        self.common_change_types = List[String]()
        self.common_change_counts = List[UInt32]()
        self.peak_hours = List[Int]()
        self.avg_commit_granularity = 0.0
        self.file_couplings = List[FileCouple]()
        self.total_sessions = 0
        self.total_prompts = 0

    fn __init__(out self, *, copy: Self):
        self.preferred_languages = copy.preferred_languages.copy()
        self.avg_session_length_mins = copy.avg_session_length_mins
        self.reprompt_rate = copy.reprompt_rate
        self.tool_call_frequency = copy.tool_call_frequency
        self.common_change_types = copy.common_change_types.copy()
        self.common_change_counts = copy.common_change_counts.copy()
        self.peak_hours = copy.peak_hours.copy()
        self.avg_commit_granularity = copy.avg_commit_granularity
        self.file_couplings = copy.file_couplings.copy()
        self.total_sessions = copy.total_sessions
        self.total_prompts = copy.total_prompts

    fn __moveinit__(out self, deinit take: Self):
        self.preferred_languages = take.preferred_languages^
        self.avg_session_length_mins = take.avg_session_length_mins
        self.reprompt_rate = take.reprompt_rate
        self.tool_call_frequency = take.tool_call_frequency
        self.common_change_types = take.common_change_types^
        self.common_change_counts = take.common_change_counts^
        self.peak_hours = take.peak_hours^
        self.avg_commit_granularity = take.avg_commit_granularity
        self.file_couplings = take.file_couplings^
        self.total_sessions = take.total_sessions
        self.total_prompts = take.total_prompts

    fn to_json(self) -> String:
        """Serialize to JSON matching the TypeScript DeveloperProfile interface."""
        var langs_json = String("[")
        for i in range(len(self.preferred_languages)):
            if i > 0:
                langs_json += ", "
            langs_json += _json_str(self.preferred_languages[i])
        langs_json += "]"

        var hours_json = String("[")
        for i in range(len(self.peak_hours)):
            if i > 0:
                hours_json += ", "
            hours_json += String(self.peak_hours[i])
        hours_json += "]"

        var change_json = String("{")
        for i in range(len(self.common_change_types)):
            if i > 0:
                change_json += ", "
            change_json += (
                _json_str(self.common_change_types[i])
                + ": "
                + String(Int(self.common_change_counts[i]))
            )
        change_json += "}"

        var couplings_json = String("[")
        for i in range(min(20, len(self.file_couplings))):
            if i > 0:
                couplings_json += ", "
            couplings_json += (
                '{"fileA": '
                + _json_str(self.file_couplings[i].file_a)
                + ', "fileB": '
                + _json_str(self.file_couplings[i].file_b)
                + ', "count": '
                + String(self.file_couplings[i].co_edit_count)
                + "}"
            )
        couplings_json += "]"

        return (
            '{"preferredLanguages": '
            + langs_json
            + ', "avgSessionLengthMins": '
            + _json_f32(self.avg_session_length_mins)
            + ', "repromptRate": '
            + _json_f32(self.reprompt_rate)
            + ', "toolCallFrequency": '
            + _json_f32(self.tool_call_frequency)
            + ', "commonChangeTypes": '
            + change_json
            + ', "peakHours": '
            + hours_json
            + ', "avgCommitGranularity": '
            + _json_f32(self.avg_commit_granularity)
            + ', "fileCouplings": '
            + couplings_json
            + ', "totalSessions": '
            + String(self.total_sessions)
            + ', "totalPrompts": '
            + String(self.total_prompts)
            + "}"
        )


fn generate_profile(
    commits: List[CommitData],
    temporal: TemporalPattern,
    couplings: List[FileCouple],
) -> DeveloperProfile:
    """Generate a developer profile from analyzed data."""
    var profile = DeveloperProfile()

    # Languages
    profile.preferred_languages = detect_languages(commits)

    # Peak hours
    profile.peak_hours = temporal.peak_hours.copy()

    # Commit granularity
    profile.avg_commit_granularity = compute_commit_granularity(commits)

    # Change type distribution
    for ci in range(len(commits)):
        var ct = commits[ci].change_type
        var found = False
        for ti in range(len(profile.common_change_types)):
            if profile.common_change_types[ti] == ct:
                profile.common_change_counts[ti] += 1
                found = True
                break
        if not found:
            profile.common_change_types.append(ct)
            profile.common_change_counts.append(1)

    # File couplings (top 20)
    var limit = min(20, len(couplings))
    for i in range(limit):
        var fc_copy = FileCouple(copy=couplings[i])
        profile.file_couplings.append(fc_copy^)

    return profile^


fn generate_claude_context_md(profile: DeveloperProfile) -> String:
    """Generate a claude_context.md file content for feeding to Claude."""
    var md = String("# Developer Context for Claude\n\n")
    md += "This file was auto-generated by CodeLens to help Claude understand your development patterns.\n\n"

    md += "## Preferred Languages\n"
    for i in range(len(profile.preferred_languages)):
        md += "- " + profile.preferred_languages[i] + "\n"
    md += "\n"

    md += "## Productivity Patterns\n"
    md += "- Peak coding hours: "
    for i in range(len(profile.peak_hours)):
        if i > 0:
            md += ", "
        md += String(profile.peak_hours[i]) + ":00"
    md += "\n"
    md += "- Average commit granularity: " + _json_f32(profile.avg_commit_granularity) + " files/commit\n"
    md += "\n"

    md += "## Common Change Types\n"
    for i in range(len(profile.common_change_types)):
        md += "- " + profile.common_change_types[i] + ": " + String(Int(profile.common_change_counts[i])) + " commits\n"
    md += "\n"

    md += "## Frequently Co-edited Files\n"
    var limit = min(10, len(profile.file_couplings))
    for i in range(limit):
        md += "- " + profile.file_couplings[i].file_a + " <-> " + profile.file_couplings[i].file_b + " (" + String(profile.file_couplings[i].co_edit_count) + "x)\n"
    md += "\n"

    return md^
