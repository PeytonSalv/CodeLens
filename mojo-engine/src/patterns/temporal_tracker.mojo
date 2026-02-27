"""Track commit frequency by hour/day/week.

Detect productivity patterns: peak hours, sprint/rest cycles.
"""

from ..types import CommitData


struct TemporalPattern(Copyable, Movable):
    """Aggregated temporal statistics."""

    # Commits per hour (24 slots)
    var hour_counts: List[UInt32]
    # Commits per day of week (7 slots, 0=Monday)
    var day_counts: List[UInt32]
    # Peak hours (indices into hour_counts where activity is highest)
    var peak_hours: List[Int]
    # Average gap between sessions in hours
    var avg_session_gap_hours: Float32

    fn __init__(out self):
        self.hour_counts = List[UInt32]()
        for _ in range(24):
            self.hour_counts.append(0)
        self.day_counts = List[UInt32]()
        for _ in range(7):
            self.day_counts.append(0)
        self.peak_hours = List[Int]()
        self.avg_session_gap_hours = 0.0

    fn __init__(out self, *, copy: Self):
        self.hour_counts = copy.hour_counts.copy()
        self.day_counts = copy.day_counts.copy()
        self.peak_hours = copy.peak_hours.copy()
        self.avg_session_gap_hours = copy.avg_session_gap_hours

    fn __moveinit__(out self, deinit take: Self):
        self.hour_counts = take.hour_counts^
        self.day_counts = take.day_counts^
        self.peak_hours = take.peak_hours^
        self.avg_session_gap_hours = take.avg_session_gap_hours


fn track_temporal_patterns(commits: List[CommitData]) raises -> TemporalPattern:
    """Analyze commit timestamps to detect temporal patterns.

    Extracts hour and day-of-week distributions, identifies peak hours,
    and computes average session gaps.
    """
    from python import Python

    var datetime = Python.import_module("datetime")
    var builtins = Python.import_module("builtins")
    var pattern = TemporalPattern()

    var epochs = List[Int]()

    for ci in range(len(commits)):
        var ts = commits[ci].timestamp
        if ts == "":
            continue

        try:
            var dt = datetime.datetime.fromisoformat(String(ts))
            var hour = Int(py=dt.hour)
            var weekday = Int(py=dt.weekday())  # 0=Monday

            pattern.hour_counts[hour] += 1
            pattern.day_counts[weekday] += 1

            var epoch_ref = datetime.datetime(1970, 1, 1, tzinfo=datetime.timezone.utc)
            var delta = dt - epoch_ref
            epochs.append(Int(py=delta.total_seconds()))
        except:
            continue

    # Find peak hours (top 3 hours by commit count)
    var sorted_hours = List[Int]()
    for h in range(24):
        sorted_hours.append(h)

    for i in range(len(sorted_hours)):
        var max_idx = i
        for j in range(i + 1, len(sorted_hours)):
            if pattern.hour_counts[sorted_hours[j]] > pattern.hour_counts[sorted_hours[max_idx]]:
                max_idx = j
        if max_idx != i:
            var tmp = sorted_hours[i]
            sorted_hours[i] = sorted_hours[max_idx]
            sorted_hours[max_idx] = tmp

    for i in range(min(3, len(sorted_hours))):
        if pattern.hour_counts[sorted_hours[i]] > 0:
            pattern.peak_hours.append(sorted_hours[i])

    # Compute average session gap
    if len(epochs) > 1:
        # Sort epochs
        for i in range(len(epochs)):
            for j in range(i + 1, len(epochs)):
                if epochs[j] < epochs[i]:
                    var tmp = epochs[i]
                    epochs[i] = epochs[j]
                    epochs[j] = tmp

        var total_gap: Int = 0
        var gap_count: Int = 0
        var four_hours: Int = 4 * 60 * 60

        for i in range(1, len(epochs)):
            var gap = epochs[i] - epochs[i - 1]
            if gap > four_hours:
                total_gap += gap
                gap_count += 1

        if gap_count > 0:
            pattern.avg_session_gap_hours = Float32(total_gap) / Float32(gap_count) / 3600.0

    return pattern^
