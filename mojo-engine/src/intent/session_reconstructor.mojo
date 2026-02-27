"""Parse JSONL session into ordered sequence of prompt -> tool calls -> file edits.

Reconstructs the development timeline from Claude Code session data.
"""


struct SessionEvent(Copyable, Movable):
    """A single event in the session timeline."""

    var event_type: String  # "prompt", "tool_call", "file_edit", "file_read"
    var timestamp: String
    var content: String  # prompt text, tool name, or file path
    var detail: String  # tool input summary or edit type
    var file_path: String  # relevant file if applicable

    fn __init__(out self):
        self.event_type = String("")
        self.timestamp = String("")
        self.content = String("")
        self.detail = String("")
        self.file_path = String("")

    fn __init__(out self, *, copy: Self):
        self.event_type = copy.event_type
        self.timestamp = copy.timestamp
        self.content = copy.content
        self.detail = copy.detail
        self.file_path = copy.file_path

    fn __moveinit__(out self, deinit take: Self):
        self.event_type = take.event_type^
        self.timestamp = take.timestamp^
        self.content = take.content^
        self.detail = take.detail^
        self.file_path = take.file_path^


struct ReconstructedSession(Copyable, Movable):
    """A fully reconstructed session with ordered events."""

    var session_id: String
    var events: List[SessionEvent]
    var prompt_count: Int
    var tool_call_count: Int
    var files_read: List[String]
    var files_written: List[String]
    var total_duration_secs: Int

    fn __init__(out self):
        self.session_id = String("")
        self.events = List[SessionEvent]()
        self.prompt_count = 0
        self.tool_call_count = 0
        self.files_read = List[String]()
        self.files_written = List[String]()
        self.total_duration_secs = 0

    fn __init__(out self, *, copy: Self):
        self.session_id = copy.session_id
        self.events = copy.events.copy()
        self.prompt_count = copy.prompt_count
        self.tool_call_count = copy.tool_call_count
        self.files_read = copy.files_read.copy()
        self.files_written = copy.files_written.copy()
        self.total_duration_secs = copy.total_duration_secs

    fn __moveinit__(out self, deinit take: Self):
        self.session_id = take.session_id^
        self.events = take.events^
        self.prompt_count = take.prompt_count
        self.tool_call_count = take.tool_call_count
        self.files_read = take.files_read^
        self.files_written = take.files_written^
        self.total_duration_secs = take.total_duration_secs


fn reconstruct_session(
    session_path: String, session_id: String
) raises -> ReconstructedSession:
    """Reconstruct a session timeline from a JSONL file.

    Parses each line and builds an ordered event sequence.
    """
    from python import Python

    var json_mod = Python.import_module("json")
    var builtins = Python.import_module("builtins")

    var session = ReconstructedSession()
    session.session_id = session_id

    var files_read_set = List[String]()
    var files_written_set = List[String]()

    var f = builtins.open(String(session_path), "r", encoding="utf-8")
    for line in f:
        var line_raw = String(line)
        var line_str = String(line_raw.strip())
        if line_str == "":
            continue

        try:
            var obj = json_mod.loads(line_str)
            var msg_type = String(obj.get("type", ""))
            var timestamp = String(obj.get("timestamp", ""))

            if msg_type == "user":
                var empty_dict = builtins.dict()
                var msg = obj.get("message", empty_dict)
                var content = msg.get("content", "")
                if builtins.isinstance(content, builtins.str):
                    var text_raw = String(content)
                    var text = String(text_raw.strip())
                    if text != "":
                        var event = SessionEvent()
                        event.event_type = "prompt"
                        event.timestamp = timestamp
                        event.content = text
                        session.events.append(event^)
                        session.prompt_count += 1

            elif msg_type == "assistant":
                var empty_dict2 = builtins.dict()
                var msg = obj.get("message", empty_dict2)
                var empty_list = builtins.list()
                var content_arr = msg.get("content", empty_list)
                if builtins.isinstance(content_arr, builtins.list):
                    for block in content_arr:
                        var block_type = String(block.get("type", ""))
                        if block_type == "tool_use":
                            var tool_name = String(block.get("name", ""))
                            var empty_dict3 = builtins.dict()
                            var input_data = block.get("input", empty_dict3)
                            session.tool_call_count += 1

                            var event = SessionEvent()
                            event.event_type = "tool_call"
                            event.timestamp = timestamp
                            event.content = tool_name

                            # Extract file path from tool input
                            if tool_name == "Write" or tool_name == "Edit" or tool_name == "Read":
                                var fp = String(input_data.get("file_path", ""))
                                event.file_path = fp
                                if tool_name == "Read":
                                    event.event_type = "file_read"
                                    _add_unique(files_read_set, fp)
                                else:
                                    event.event_type = "file_edit"
                                    _add_unique(files_written_set, fp)

                            session.events.append(event^)

        except:
            continue

    f.close()

    session.files_read = files_read_set^
    session.files_written = files_written_set^

    return session^


fn _add_unique(mut lst: List[String], item: String):
    """Add item to list if not already present."""
    for i in range(len(lst)):
        if lst[i] == item:
            return
    lst.append(item)
