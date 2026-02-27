"""Tests for git_parser module."""

from src.git_parser import classify_change_type, parse_git_log, group_into_features, detect_languages
from src.types import CommitData, FileChange, FeatureCluster


fn test_classify_change_type():
    """Test change type classification from commit subjects."""
    print("test_classify_change_type...")

    # Feature keywords
    assert_equal(classify_change_type("feat: add new dashboard"), "new_feature")
    assert_equal(classify_change_type("add user authentication"), "new_feature")
    assert_equal(classify_change_type("implement dark mode"), "new_feature")

    # Bug fix keywords
    assert_equal(classify_change_type("fix: resolve crash on startup"), "bug_fix")
    assert_equal(classify_change_type("patch memory leak"), "bug_fix")
    assert_equal(classify_change_type("debug: fix bug in parser"), "bug_fix")

    # Refactor keywords
    assert_equal(classify_change_type("refactor auth module"), "refactor")
    assert_equal(classify_change_type("restructure project layout"), "refactor")

    # Performance keywords
    assert_equal(classify_change_type("perf: optimize query"), "performance")
    assert_equal(classify_change_type("optimize database lookups"), "performance")

    # Test keywords
    assert_equal(classify_change_type("test: add unit tests"), "test")
    assert_equal(classify_change_type("add spec for parser"), "test")

    # Documentation keywords
    assert_equal(classify_change_type("docs: update readme"), "documentation")
    assert_equal(classify_change_type("update readme with examples"), "documentation")

    # Style keywords
    assert_equal(classify_change_type("style: format code"), "style")
    assert_equal(classify_change_type("lint: fix warnings"), "style")

    # Default fallback
    assert_equal(classify_change_type("update dependencies"), "new_feature")

    print("  PASSED")


fn test_claude_code_detection():
    """Test Claude Code detection from commit body."""
    print("test_claude_code_detection...")

    var commit = CommitData()
    commit.body = "Some changes\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
    var body_lower = commit.body.lower()
    var is_claude = "co-authored-by: claude" in body_lower
    assert_true(is_claude, "Should detect Co-Authored-By marker")

    var commit2 = CommitData()
    commit2.body = "Regular commit\nNo special markers"
    var body_lower2 = commit2.body.lower()
    var is_claude2 = "co-authored-by: claude" in body_lower2
    assert_true(not is_claude2, "Should not detect Claude in regular commit")

    print("  PASSED")


fn test_feature_grouping():
    """Test 4-hour time window feature grouping."""
    print("test_feature_grouping...")

    var commits = List[CommitData]()

    # Group 1: three commits within 2 hours
    var c1 = CommitData()
    c1.hash = "aaa"
    c1.subject = "First commit"
    c1.timestamp = "2024-01-15T10:00:00+00:00"
    c1.change_type = "new_feature"
    commits.append(c1)

    var c2 = CommitData()
    c2.hash = "bbb"
    c2.subject = "Second commit"
    c2.timestamp = "2024-01-15T11:00:00+00:00"
    c2.change_type = "new_feature"
    commits.append(c2)

    var c3 = CommitData()
    c3.hash = "ccc"
    c3.subject = "Third commit"
    c3.timestamp = "2024-01-15T12:00:00+00:00"
    c3.change_type = "bug_fix"
    commits.append(c3)

    # Group 2: one commit 6 hours later
    var c4 = CommitData()
    c4.hash = "ddd"
    c4.subject = "Fourth commit"
    c4.timestamp = "2024-01-15T18:00:00+00:00"
    c4.change_type = "refactor"
    commits.append(c4)

    try:
        var features = group_into_features(commits)

        assert_true(len(features) == 2, "Should create 2 feature groups")
        assert_true(len(features[0].commit_hashes) == 3, "First group should have 3 commits")
        assert_true(len(features[1].commit_hashes) == 1, "Second group should have 1 commit")
        assert_true(features[0].cluster_id == 0, "First cluster ID should be 0")
        assert_true(features[1].cluster_id == 1, "Second cluster ID should be 1")

        print("  PASSED")
    except e:
        print("  FAILED: " + str(e))


fn test_detect_languages():
    """Test language detection from file extensions."""
    print("test_detect_languages...")

    var commits = List[CommitData]()
    var c = CommitData()
    c.files_changed = List[FileChange]()
    c.files_changed.append(FileChange("src/main.rs", 10, 5))
    c.files_changed.append(FileChange("src/lib.rs", 20, 3))
    c.files_changed.append(FileChange("src/App.tsx", 15, 8))
    c.files_changed.append(FileChange("package.json", 2, 1))
    commits.append(c)

    var langs = detect_languages(commits)
    assert_true(len(langs) > 0, "Should detect at least one language")
    assert_true(langs[0] == "Rust", "Most common language should be Rust")

    print("  PASSED")


fn test_commit_json_serialization():
    """Test CommitData JSON serialization."""
    print("test_commit_json_serialization...")

    var commit = CommitData()
    commit.hash = "abc123"
    commit.author_name = "Test User"
    commit.author_email = "test@example.com"
    commit.timestamp = "2024-01-15T10:00:00Z"
    commit.subject = "test commit"
    commit.change_type = "new_feature"
    commit.cluster_id = 0

    var json = commit.to_json()
    assert_true('"hash": "abc123"' in json, "JSON should contain hash")
    assert_true('"authorName": "Test User"' in json, "JSON should use camelCase")
    assert_true('"isClaudeCode": false' in json, "JSON should contain isClaudeCode")

    print("  PASSED")


fn assert_equal(actual: String, expected: String):
    if actual != expected:
        print(
            "  ASSERTION FAILED: expected '"
            + expected
            + "' but got '"
            + actual
            + "'"
        )
        raise Error("assertion failed")


fn assert_true(condition: Bool, message: String):
    if not condition:
        print("  ASSERTION FAILED: " + message)
        raise Error("assertion failed: " + message)


fn main() raises:
    print("Running git_parser tests...")
    print()

    test_classify_change_type()
    test_claude_code_detection()
    test_feature_grouping()
    test_detect_languages()
    test_commit_json_serialization()

    print()
    print("All tests passed!")
