"""Project-level types matching Rust ProjectData, Analytics, RepositoryInfo."""

from .commit import CommitData, _json_str, _json_f32
from .feature import FeatureCluster, SubFeature, _string_list_json


struct DateRange(Copyable, Movable):
    var start: String
    var end: String

    fn __init__(out self):
        self.start = String("")
        self.end = String("")

    fn __init__(out self, *, copy: Self):
        self.start = copy.start
        self.end = copy.end

    fn __moveinit__(out self, deinit take: Self):
        self.start = take.start^
        self.end = take.end^

    fn to_json(self) -> String:
        return (
            '{"start": '
            + _json_str(self.start)
            + ', "end": '
            + _json_str(self.end)
            + "}"
        )


struct RepositoryInfo(Copyable, Movable):
    var path: String
    var name: String
    var total_commits: UInt32
    var date_range: DateRange
    var languages_detected: List[String]

    fn __init__(out self):
        self.path = String("")
        self.name = String("")
        self.total_commits = 0
        self.date_range = DateRange()
        self.languages_detected = List[String]()

    fn __init__(out self, *, copy: Self):
        self.path = copy.path
        self.name = copy.name
        self.total_commits = copy.total_commits
        self.date_range = DateRange(copy=copy.date_range)
        self.languages_detected = copy.languages_detected.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.path = take.path^
        self.name = take.name^
        self.total_commits = take.total_commits
        self.date_range = take.date_range^
        self.languages_detected = take.languages_detected^

    fn to_json(self) -> String:
        return (
            '{"path": '
            + _json_str(self.path)
            + ', "name": '
            + _json_str(self.name)
            + ', "totalCommits": '
            + String(Int(self.total_commits))
            + ', "dateRange": '
            + self.date_range.to_json()
            + ', "languagesDetected": '
            + _string_list_json(self.languages_detected)
            + "}"
        )


struct WeekVelocity(Copyable, Movable):
    var week: String
    var features: UInt32
    var commits: UInt32

    fn __init__(out self):
        self.week = String("")
        self.features = 0
        self.commits = 0

    fn __init__(out self, *, copy: Self):
        self.week = copy.week
        self.features = copy.features
        self.commits = copy.commits

    fn __moveinit__(out self, deinit take: Self):
        self.week = take.week^
        self.features = take.features
        self.commits = take.commits

    fn to_json(self) -> String:
        return (
            '{"week": '
            + _json_str(self.week)
            + ', "features": '
            + String(Int(self.features))
            + ', "commits": '
            + String(Int(self.commits))
            + "}"
        )


struct Analytics(Copyable, Movable):
    var total_features: UInt32
    var total_functions_modified: UInt32
    var total_prompts_detected: UInt32
    var claude_code_commit_percentage: Float32
    var avg_prompt_similarity: Float32
    var most_modified_files: List[String]
    var most_modified_functions: List[String]
    # change_type_totals as parallel lists
    var change_type_keys: List[String]
    var change_type_values: List[UInt32]
    var velocity_by_week: List[WeekVelocity]

    fn __init__(out self):
        self.total_features = 0
        self.total_functions_modified = 0
        self.total_prompts_detected = 0
        self.claude_code_commit_percentage = 0.0
        self.avg_prompt_similarity = 0.0
        self.most_modified_files = List[String]()
        self.most_modified_functions = List[String]()
        self.change_type_keys = List[String]()
        self.change_type_values = List[UInt32]()
        self.velocity_by_week = List[WeekVelocity]()

    fn __init__(out self, *, copy: Self):
        self.total_features = copy.total_features
        self.total_functions_modified = copy.total_functions_modified
        self.total_prompts_detected = copy.total_prompts_detected
        self.claude_code_commit_percentage = copy.claude_code_commit_percentage
        self.avg_prompt_similarity = copy.avg_prompt_similarity
        self.most_modified_files = copy.most_modified_files.copy()
        self.most_modified_functions = copy.most_modified_functions.copy()
        self.change_type_keys = copy.change_type_keys.copy()
        self.change_type_values = copy.change_type_values.copy()
        self.velocity_by_week = copy.velocity_by_week.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.total_features = take.total_features
        self.total_functions_modified = take.total_functions_modified
        self.total_prompts_detected = take.total_prompts_detected
        self.claude_code_commit_percentage = take.claude_code_commit_percentage
        self.avg_prompt_similarity = take.avg_prompt_similarity
        self.most_modified_files = take.most_modified_files^
        self.most_modified_functions = take.most_modified_functions^
        self.change_type_keys = take.change_type_keys^
        self.change_type_values = take.change_type_values^
        self.velocity_by_week = take.velocity_by_week^

    fn add_change_type(mut self, key: String, value: UInt32):
        for i in range(len(self.change_type_keys)):
            if self.change_type_keys[i] == key:
                self.change_type_values[i] += value
                return
        self.change_type_keys.append(key)
        self.change_type_values.append(value)

    fn to_json(self) -> String:
        # Build change_type_totals object
        var totals_json = String("{")
        for i in range(len(self.change_type_keys)):
            if i > 0:
                totals_json += ", "
            totals_json += _json_str(self.change_type_keys[i]) + ": " + String(
                Int(self.change_type_values[i])
            )
        totals_json += "}"

        # Build velocity array
        var vel_json = String("[")
        for i in range(len(self.velocity_by_week)):
            if i > 0:
                vel_json += ", "
            vel_json += self.velocity_by_week[i].to_json()
        vel_json += "]"

        return (
            '{"totalFeatures": '
            + String(Int(self.total_features))
            + ', "totalFunctionsModified": '
            + String(Int(self.total_functions_modified))
            + ', "totalPromptsDetected": '
            + String(Int(self.total_prompts_detected))
            + ', "claudeCodeCommitPercentage": '
            + _json_f32(self.claude_code_commit_percentage)
            + ', "avgPromptSimilarity": '
            + _json_f32(self.avg_prompt_similarity)
            + ', "mostModifiedFiles": '
            + _string_list_json(self.most_modified_files)
            + ', "mostModifiedFunctions": '
            + _string_list_json(self.most_modified_functions)
            + ', "changeTypeTotals": '
            + totals_json
            + ', "velocityByWeek": '
            + vel_json
            + "}"
        )


struct ScanProgress(Copyable, Movable):
    """Progress update sent to stdout for the Rust bridge."""

    var stage: String
    var progress: Float32
    var message: String

    fn __init__(out self):
        self.stage = String("")
        self.progress = 0.0
        self.message = String("")

    fn __init__(out self, stage: String, progress: Float32, message: String):
        self.stage = stage
        self.progress = progress
        self.message = message

    fn __init__(out self, *, copy: Self):
        self.stage = copy.stage
        self.progress = copy.progress
        self.message = copy.message

    fn __moveinit__(out self, deinit take: Self):
        self.stage = take.stage^
        self.progress = take.progress
        self.message = take.message^

    fn to_json(self) -> String:
        return (
            '{"stage": '
            + _json_str(self.stage)
            + ', "progress": '
            + _json_f32(self.progress)
            + ', "message": '
            + _json_str(self.message)
            + "}"
        )


struct ProjectData(Copyable, Movable):
    """Complete project scan output matching Rust ProjectData."""

    var repository: RepositoryInfo
    var commits: List[CommitData]
    var features: List[FeatureCluster]
    # prompt_sessions are handled by Rust side, but we include empty list for schema compat
    var analytics: Analytics

    fn __init__(out self):
        self.repository = RepositoryInfo()
        self.commits = List[CommitData]()
        self.features = List[FeatureCluster]()
        self.analytics = Analytics()

    fn __init__(out self, *, copy: Self):
        self.repository = RepositoryInfo(copy=copy.repository)
        self.commits = copy.commits.copy()
        self.features = copy.features.copy()
        self.analytics = Analytics(copy=copy.analytics)

    fn __moveinit__(out self, deinit take: Self):
        self.repository = take.repository^
        self.commits = take.commits^
        self.features = take.features^
        self.analytics = take.analytics^

    fn to_json(self) -> String:
        var commits_json = String("[")
        for i in range(len(self.commits)):
            if i > 0:
                commits_json += ", "
            commits_json += self.commits[i].to_json()
        commits_json += "]"

        var features_json = String("[")
        for i in range(len(self.features)):
            if i > 0:
                features_json += ", "
            features_json += self.features[i].to_json()
        features_json += "]"

        return (
            '{"repository": '
            + self.repository.to_json()
            + ', "commits": '
            + commits_json
            + ', "features": '
            + features_json
            + ', "promptSessions": []'
            + ', "analytics": '
            + self.analytics.to_json()
            + "}"
        )
