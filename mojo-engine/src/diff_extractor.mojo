"""Diff extractor — shells out to git diff-tree to populate FileChange on each commit.

Port of scan.rs:170-203 get_file_stats().
"""

from .types import CommitData, FileChange


fn extract_file_stats(repo_path: String, mut commits: List[CommitData]) raises:
    """Populate files_changed on each commit via git diff-tree --numstat.

    For each commit, runs:
      git diff-tree --numstat --no-commit-id -r <hash>
    and parses output lines of the form:
      <added>\t<removed>\t<path>
    """
    from python import Python

    var subprocess = Python.import_module("subprocess")
    var builtins = Python.import_module("builtins")

    for i in range(len(commits)):
        var hash_val = commits[i].hash
        var cmd = builtins.list()
        cmd.append("git")
        cmd.append("diff-tree")
        cmd.append("--numstat")
        cmd.append("--no-commit-id")
        cmd.append("-r")
        cmd.append(String(hash_val))
        var result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=String(repo_path),
        )

        if Int(py=result.returncode) != 0:
            continue

        var stdout = String(result.stdout)
        var files = List[FileChange]()

        var lines = stdout.split("\n")
        for li in range(len(lines)):
            var line_raw = String(lines[li])
            var line = String(line_raw.strip())
            if line == "":
                continue

            # Parse tab-separated: added\tremoved\tpath
            var parts = line.split("\t")
            if len(parts) < 3:
                continue

            var added_raw = String(parts[0])
            var added_str = String(added_raw.strip())
            var removed_raw = String(parts[1])
            var removed_str = String(removed_raw.strip())
            var path_raw = String(parts[2])
            var file_path = String(path_raw.strip())

            # Binary files show as '-' for lines
            var lines_added: UInt32 = 0
            var lines_removed: UInt32 = 0
            if added_str != "-":
                try:
                    lines_added = UInt32(Int(added_str))
                except:
                    lines_added = 0
            if removed_str != "-":
                try:
                    lines_removed = UInt32(Int(removed_str))
                except:
                    lines_removed = 0

            files.append(FileChange(file_path, lines_added, lines_removed))

        commits[i].files_changed = files^
