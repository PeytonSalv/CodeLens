"""Commit data types matching Rust CommitData, FileChange, FunctionChange."""


struct FunctionChange(Copyable, Movable):
    """A function-level change within a file."""

    var name: String
    var lines_added: UInt32
    var lines_removed: UInt32
    var diff_text: String

    fn __init__(out self):
        self.name = String("")
        self.lines_added = 0
        self.lines_removed = 0
        self.diff_text = String("")

    fn __init__(out self, *, copy: Self):
        self.name = copy.name
        self.lines_added = copy.lines_added
        self.lines_removed = copy.lines_removed
        self.diff_text = copy.diff_text

    fn __moveinit__(out self, deinit take: Self):
        self.name = take.name^
        self.lines_added = take.lines_added
        self.lines_removed = take.lines_removed
        self.diff_text = take.diff_text^

    fn to_json(self) -> String:
        """Serialize to JSON string."""
        return (
            '{"name": '
            + _json_str(self.name)
            + ', "linesAdded": '
            + String(Int(self.lines_added))
            + ', "linesRemoved": '
            + String(Int(self.lines_removed))
            + ', "diffText": '
            + _json_str(self.diff_text)
            + "}"
        )


struct FileChange(Copyable, Movable):
    """A file changed in a commit with line stats."""

    var path: String
    var lines_added: UInt32
    var lines_removed: UInt32
    var functions: List[FunctionChange]

    fn __init__(out self):
        self.path = String("")
        self.lines_added = 0
        self.lines_removed = 0
        self.functions = List[FunctionChange]()

    fn __init__(out self, path: String, lines_added: UInt32, lines_removed: UInt32):
        self.path = path
        self.lines_added = lines_added
        self.lines_removed = lines_removed
        self.functions = List[FunctionChange]()

    fn __init__(out self, *, copy: Self):
        self.path = copy.path
        self.lines_added = copy.lines_added
        self.lines_removed = copy.lines_removed
        self.functions = copy.functions.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.path = take.path^
        self.lines_added = take.lines_added
        self.lines_removed = take.lines_removed
        self.functions = take.functions^

    fn to_json(self) -> String:
        """Serialize to JSON string."""
        var funcs_json = String("[")
        for i in range(len(self.functions)):
            if i > 0:
                funcs_json += ", "
            funcs_json += self.functions[i].to_json()
        funcs_json += "]"

        return (
            '{"path": '
            + _json_str(self.path)
            + ', "linesAdded": '
            + String(Int(self.lines_added))
            + ', "linesRemoved": '
            + String(Int(self.lines_removed))
            + ', "functions": '
            + funcs_json
            + "}"
        )


struct CommitData(Copyable, Movable):
    """A single git commit with metadata and file changes."""

    var hash: String
    var author_name: String
    var author_email: String
    var timestamp: String
    var subject: String
    var body: String
    var is_claude_code: Bool
    var session_id: String  # empty string = None
    var change_type: String
    var change_type_confidence: Float32
    var cluster_id: Int32
    var files_changed: List[FileChange]

    fn __init__(out self):
        self.hash = String("")
        self.author_name = String("")
        self.author_email = String("")
        self.timestamp = String("")
        self.subject = String("")
        self.body = String("")
        self.is_claude_code = False
        self.session_id = String("")
        self.change_type = String("new_feature")
        self.change_type_confidence = 0.7
        self.cluster_id = -1
        self.files_changed = List[FileChange]()

    fn __init__(out self, *, copy: Self):
        self.hash = copy.hash
        self.author_name = copy.author_name
        self.author_email = copy.author_email
        self.timestamp = copy.timestamp
        self.subject = copy.subject
        self.body = copy.body
        self.is_claude_code = copy.is_claude_code
        self.session_id = copy.session_id
        self.change_type = copy.change_type
        self.change_type_confidence = copy.change_type_confidence
        self.cluster_id = copy.cluster_id
        self.files_changed = copy.files_changed.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.hash = take.hash^
        self.author_name = take.author_name^
        self.author_email = take.author_email^
        self.timestamp = take.timestamp^
        self.subject = take.subject^
        self.body = take.body^
        self.is_claude_code = take.is_claude_code
        self.session_id = take.session_id^
        self.change_type = take.change_type^
        self.change_type_confidence = take.change_type_confidence
        self.cluster_id = take.cluster_id
        self.files_changed = take.files_changed^

    fn to_json(self) -> String:
        """Serialize to JSON string matching camelCase format."""
        var files_json = String("[")
        for i in range(len(self.files_changed)):
            if i > 0:
                files_json += ", "
            files_json += self.files_changed[i].to_json()
        files_json += "]"

        var session_id_json: String
        if self.session_id == "":
            session_id_json = "null"
        else:
            session_id_json = _json_str(self.session_id)

        return (
            '{"hash": '
            + _json_str(self.hash)
            + ', "authorName": '
            + _json_str(self.author_name)
            + ', "authorEmail": '
            + _json_str(self.author_email)
            + ', "timestamp": '
            + _json_str(self.timestamp)
            + ', "subject": '
            + _json_str(self.subject)
            + ', "body": '
            + _json_str(self.body)
            + ', "isClaudeCode": '
            + _json_bool(self.is_claude_code)
            + ', "sessionId": '
            + session_id_json
            + ', "changeType": '
            + _json_str(self.change_type)
            + ', "changeTypeConfidence": '
            + _json_f32(self.change_type_confidence)
            + ', "clusterId": '
            + String(Int(self.cluster_id))
            + ', "filesChanged": '
            + files_json
            + "}"
        )


fn _json_str(s: String) -> String:
    """Escape a string for JSON output."""
    var result = String('"')
    for i in range(len(s)):
        var byte_val = s.as_bytes()[i]
        if byte_val == UInt8(ord('"')):
            result += '\\"'
        elif byte_val == UInt8(ord("\\")):
            result += "\\\\"
        elif byte_val == UInt8(ord("\n")):
            result += "\\n"
        elif byte_val == UInt8(ord("\r")):
            result += "\\r"
        elif byte_val == UInt8(ord("\t")):
            result += "\\t"
        else:
            # Append the character byte directly
            result += chr(Int(byte_val))
    result += '"'
    return result^


fn _json_bool(b: Bool) -> String:
    if b:
        return "true"
    return "false"


fn _json_f32(f: Float32) -> String:
    """Format a float32 to a reasonable JSON number."""
    # Simple approach: use integer math for 2 decimal places
    var int_part = Int(f)
    var frac = f - Float32(int_part)
    if frac < 0:
        frac = -frac
    var frac_int = Int(frac * 100.0)
    if frac_int < 10:
        return String(int_part) + ".0" + String(frac_int)
    return String(int_part) + "." + String(frac_int)
