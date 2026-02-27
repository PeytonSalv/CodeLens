"""Feature cluster and sub-feature types matching Rust FeatureCluster, SubFeature."""

from .commit import _json_str, _json_bool, _json_f32


struct SubFeature(Copyable, Movable):
    """A prompt-derived sub-feature within a feature cluster."""

    var prompt_text: String
    var session_id: String
    var prompt_index: UInt32
    var timestamp: String
    var time_end: String  # empty = null
    var commit_hashes: List[String]
    var files_written: List[String]
    var lines_added: UInt32
    var lines_removed: UInt32
    var change_type: String
    var model: String  # empty = null

    fn __init__(out self):
        self.prompt_text = String("")
        self.session_id = String("")
        self.prompt_index = 0
        self.timestamp = String("")
        self.time_end = String("")
        self.commit_hashes = List[String]()
        self.files_written = List[String]()
        self.lines_added = 0
        self.lines_removed = 0
        self.change_type = String("new_feature")
        self.model = String("")

    fn __init__(out self, *, copy: Self):
        self.prompt_text = copy.prompt_text
        self.session_id = copy.session_id
        self.prompt_index = copy.prompt_index
        self.timestamp = copy.timestamp
        self.time_end = copy.time_end
        self.commit_hashes = copy.commit_hashes.copy()
        self.files_written = copy.files_written.copy()
        self.lines_added = copy.lines_added
        self.lines_removed = copy.lines_removed
        self.change_type = copy.change_type
        self.model = copy.model

    fn __moveinit__(out self, deinit take: Self):
        self.prompt_text = take.prompt_text^
        self.session_id = take.session_id^
        self.prompt_index = take.prompt_index
        self.timestamp = take.timestamp^
        self.time_end = take.time_end^
        self.commit_hashes = take.commit_hashes^
        self.files_written = take.files_written^
        self.lines_added = take.lines_added
        self.lines_removed = take.lines_removed
        self.change_type = take.change_type^
        self.model = take.model^

    fn to_json(self) -> String:
        var hashes_json = _string_list_json(self.commit_hashes)
        var files_json = _string_list_json(self.files_written)

        var time_end_json: String
        if self.time_end == "":
            time_end_json = "null"
        else:
            time_end_json = _json_str(self.time_end)

        var model_json: String
        if self.model == "":
            model_json = "null"
        else:
            model_json = _json_str(self.model)

        return (
            '{"promptText": '
            + _json_str(self.prompt_text)
            + ', "sessionId": '
            + _json_str(self.session_id)
            + ', "promptIndex": '
            + String(Int(self.prompt_index))
            + ', "timestamp": '
            + _json_str(self.timestamp)
            + ', "timeEnd": '
            + time_end_json
            + ', "commitHashes": '
            + hashes_json
            + ', "filesWritten": '
            + files_json
            + ', "linesAdded": '
            + String(Int(self.lines_added))
            + ', "linesRemoved": '
            + String(Int(self.lines_removed))
            + ', "changeType": '
            + _json_str(self.change_type)
            + ', "model": '
            + model_json
            + "}"
        )


struct FeatureCluster(Copyable, Movable):
    """A group of commits forming a logical feature."""

    var cluster_id: Int32
    var title: String  # empty = null
    var auto_label: String
    var narrative: String  # empty = null
    var intent: String  # empty = null
    var key_decisions: List[String]
    var commit_hashes: List[String]
    var time_start: String
    var time_end: String
    var functions_touched: List[String]
    var total_lines_added: UInt32
    var total_lines_removed: UInt32
    var primary_files: List[String]
    # change_type_distribution stored as parallel lists (keys + values)
    var change_type_keys: List[String]
    var change_type_values: List[UInt32]
    var dependencies: List[Int32]
    var sub_features: List[SubFeature]

    fn __init__(out self):
        self.cluster_id = 0
        self.title = String("")
        self.auto_label = String("")
        self.narrative = String("")
        self.intent = String("")
        self.key_decisions = List[String]()
        self.commit_hashes = List[String]()
        self.time_start = String("")
        self.time_end = String("")
        self.functions_touched = List[String]()
        self.total_lines_added = 0
        self.total_lines_removed = 0
        self.primary_files = List[String]()
        self.change_type_keys = List[String]()
        self.change_type_values = List[UInt32]()
        self.dependencies = List[Int32]()
        self.sub_features = List[SubFeature]()

    fn __init__(out self, *, copy: Self):
        self.cluster_id = copy.cluster_id
        self.title = copy.title
        self.auto_label = copy.auto_label
        self.narrative = copy.narrative
        self.intent = copy.intent
        self.key_decisions = copy.key_decisions.copy()
        self.commit_hashes = copy.commit_hashes.copy()
        self.time_start = copy.time_start
        self.time_end = copy.time_end
        self.functions_touched = copy.functions_touched.copy()
        self.total_lines_added = copy.total_lines_added
        self.total_lines_removed = copy.total_lines_removed
        self.primary_files = copy.primary_files.copy()
        self.change_type_keys = copy.change_type_keys.copy()
        self.change_type_values = copy.change_type_values.copy()
        self.dependencies = copy.dependencies.copy()
        self.sub_features = copy.sub_features.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.cluster_id = take.cluster_id
        self.title = take.title^
        self.auto_label = take.auto_label^
        self.narrative = take.narrative^
        self.intent = take.intent^
        self.key_decisions = take.key_decisions^
        self.commit_hashes = take.commit_hashes^
        self.time_start = take.time_start^
        self.time_end = take.time_end^
        self.functions_touched = take.functions_touched^
        self.total_lines_added = take.total_lines_added
        self.total_lines_removed = take.total_lines_removed
        self.primary_files = take.primary_files^
        self.change_type_keys = take.change_type_keys^
        self.change_type_values = take.change_type_values^
        self.dependencies = take.dependencies^
        self.sub_features = take.sub_features^

    fn add_change_type(mut self, key: String, value: UInt32):
        """Add or increment a change type count."""
        for i in range(len(self.change_type_keys)):
            if self.change_type_keys[i] == key:
                self.change_type_values[i] += value
                return
        self.change_type_keys.append(key)
        self.change_type_values.append(value)

    fn to_json(self) -> String:
        var title_json: String
        if self.title == "":
            title_json = "null"
        else:
            title_json = _json_str(self.title)

        var narrative_json: String
        if self.narrative == "":
            narrative_json = "null"
        else:
            narrative_json = _json_str(self.narrative)

        var intent_json: String
        if self.intent == "":
            intent_json = "null"
        else:
            intent_json = _json_str(self.intent)

        # Build change type distribution object
        var dist_json = String("{")
        for i in range(len(self.change_type_keys)):
            if i > 0:
                dist_json += ", "
            dist_json += _json_str(self.change_type_keys[i]) + ": " + String(
                Int(self.change_type_values[i])
            )
        dist_json += "}"

        # Build dependencies array
        var deps_json = String("[")
        for i in range(len(self.dependencies)):
            if i > 0:
                deps_json += ", "
            deps_json += String(Int(self.dependencies[i]))
        deps_json += "]"

        # Build sub_features array
        var subs_json = String("[")
        for i in range(len(self.sub_features)):
            if i > 0:
                subs_json += ", "
            subs_json += self.sub_features[i].to_json()
        subs_json += "]"

        return (
            '{"clusterId": '
            + String(Int(self.cluster_id))
            + ', "title": '
            + title_json
            + ', "autoLabel": '
            + _json_str(self.auto_label)
            + ', "narrative": '
            + narrative_json
            + ', "intent": '
            + intent_json
            + ', "keyDecisions": '
            + _string_list_json(self.key_decisions)
            + ', "commitHashes": '
            + _string_list_json(self.commit_hashes)
            + ', "timeStart": '
            + _json_str(self.time_start)
            + ', "timeEnd": '
            + _json_str(self.time_end)
            + ', "functionsTouched": '
            + _string_list_json(self.functions_touched)
            + ', "totalLinesAdded": '
            + String(Int(self.total_lines_added))
            + ', "totalLinesRemoved": '
            + String(Int(self.total_lines_removed))
            + ', "primaryFiles": '
            + _string_list_json(self.primary_files)
            + ', "changeTypeDistribution": '
            + dist_json
            + ', "dependencies": '
            + deps_json
            + ', "subFeatures": '
            + subs_json
            + "}"
        )


fn _string_list_json(items: List[String]) -> String:
    """Convert a list of strings to a JSON array."""
    var result = String("[")
    for i in range(len(items)):
        if i > 0:
            result += ", "
        result += _json_str(items[i])
    result += "]"
    return result^
