"""Compute what changed between consecutive file snapshots within a session."""

from .session_reconstructor import SessionEvent


struct EditDelta(Copyable, Movable):
    """Represents the change to a file between two events."""

    var file_path: String
    var edit_count: Int
    var tools_used: List[String]  # "Write", "Edit", etc.
    var first_timestamp: String
    var last_timestamp: String

    fn __init__(out self):
        self.file_path = String("")
        self.edit_count = 0
        self.tools_used = List[String]()
        self.first_timestamp = String("")
        self.last_timestamp = String("")

    fn __init__(out self, *, copy: Self):
        self.file_path = copy.file_path
        self.edit_count = copy.edit_count
        self.tools_used = copy.tools_used.copy()
        self.first_timestamp = copy.first_timestamp
        self.last_timestamp = copy.last_timestamp

    fn __moveinit__(out self, deinit take: Self):
        self.file_path = take.file_path^
        self.edit_count = take.edit_count
        self.tools_used = take.tools_used^
        self.first_timestamp = take.first_timestamp^
        self.last_timestamp = take.last_timestamp^


fn compute_edit_deltas(
    events: List[SessionEvent],
) -> List[EditDelta]:
    """Compute per-file edit deltas from a session's event list.

    Groups file edit events by path and tracks edit frequency and tools used.
    """
    # Track per-file deltas using parallel lists (simple map)
    var file_paths = List[String]()
    var deltas = List[EditDelta]()

    for i in range(len(events)):
        if events[i].event_type != "file_edit":
            continue

        var fp = events[i].file_path
        if fp == "":
            continue

        # Find or create delta for this file
        var found = False
        for di in range(len(deltas)):
            if deltas[di].file_path == fp:
                deltas[di].edit_count += 1
                deltas[di].last_timestamp = events[i].timestamp
                # Add tool if not already tracked
                var tool_found = False
                for ti in range(len(deltas[di].tools_used)):
                    if deltas[di].tools_used[ti] == events[i].content:
                        tool_found = True
                        break
                if not tool_found:
                    deltas[di].tools_used.append(events[i].content)
                found = True
                break

        if not found:
            var delta = EditDelta()
            delta.file_path = fp
            delta.edit_count = 1
            delta.tools_used.append(events[i].content)
            delta.first_timestamp = events[i].timestamp
            delta.last_timestamp = events[i].timestamp
            deltas.append(delta^)

    return deltas^
