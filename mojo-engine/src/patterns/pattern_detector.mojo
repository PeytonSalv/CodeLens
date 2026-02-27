"""Detect recurring patterns in development behavior.

Identifies:
- File couplings (files always edited together)
- Typical session flows
- Preferred commit granularity
"""

from ..types import CommitData


struct FileCouple(Copyable, Movable):
    """A pair of files frequently edited together."""

    var file_a: String
    var file_b: String
    var co_edit_count: Int

    fn __init__(out self):
        self.file_a = String("")
        self.file_b = String("")
        self.co_edit_count = 0

    fn __init__(out self, *, copy: Self):
        self.file_a = copy.file_a
        self.file_b = copy.file_b
        self.co_edit_count = copy.co_edit_count

    fn __moveinit__(out self, deinit take: Self):
        self.file_a = take.file_a^
        self.file_b = take.file_b^
        self.co_edit_count = take.co_edit_count


fn detect_file_couplings(
    commits: List[CommitData], min_count: Int = 3
) -> List[FileCouple]:
    """Detect files that are frequently edited together in the same commit.

    Returns pairs with co-edit count >= min_count, sorted by frequency.
    """
    # Track pair frequencies using parallel lists
    var pair_a = List[String]()
    var pair_b = List[String]()
    var pair_counts = List[Int]()

    for ci in range(len(commits)):
        # Generate all unique pairs in this commit
        for i in range(len(commits[ci].files_changed)):
            for j in range(i + 1, len(commits[ci].files_changed)):
                var fa = commits[ci].files_changed[i].path
                var fb = commits[ci].files_changed[j].path

                # Normalize order
                if fb < fa:
                    var tmp = fa
                    fa = fb
                    fb = tmp

                # Find or create pair
                var found = False
                for pi in range(len(pair_a)):
                    if pair_a[pi] == fa and pair_b[pi] == fb:
                        pair_counts[pi] += 1
                        found = True
                        break

                if not found:
                    pair_a.append(fa)
                    pair_b.append(fb)
                    pair_counts.append(1)

    # Filter by min_count and sort descending
    var results = List[FileCouple]()
    var indices = List[Int]()
    for i in range(len(pair_a)):
        if pair_counts[i] >= min_count:
            indices.append(i)

    # Sort by count descending
    for i in range(len(indices)):
        var max_idx = i
        for j in range(i + 1, len(indices)):
            if pair_counts[indices[j]] > pair_counts[indices[max_idx]]:
                max_idx = j
        if max_idx != i:
            var tmp = indices[i]
            indices[i] = indices[max_idx]
            indices[max_idx] = tmp

    for i in range(len(indices)):
        var idx = indices[i]
        var couple = FileCouple()
        couple.file_a = pair_a[idx]
        couple.file_b = pair_b[idx]
        couple.co_edit_count = pair_counts[idx]
        results.append(couple^)

    return results^


fn compute_commit_granularity(commits: List[CommitData]) -> Float32:
    """Compute average files changed per commit (commit granularity).

    Lower = more granular commits, Higher = larger commits.
    """
    if len(commits) == 0:
        return 0.0

    var total_files: Int = 0
    for ci in range(len(commits)):
        total_files += len(commits[ci].files_changed)

    return Float32(total_files) / Float32(len(commits))
