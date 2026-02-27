"""CodeLens Mojo Engine — main entry point.

Pipeline stages:
  Phase 1: git parsing → diff extraction → feature clustering → analytics → JSON output
  Phase 2: embeddings → semantic clustering → classification (replaces heuristics)
  Phase 4: prompt embedding → similarity scoring
  Phase 5: intent analysis
  Phase 6: pattern detection
"""

from sys import argv

from .types import (
    CommitData,
    FileChange,
    FeatureCluster,
    ProjectData,
    Analytics,
    RepositoryInfo,
    DateRange,
    WeekVelocity,
    ScanProgress,
)
from .types.commit import _json_f32
from .git_parser import (
    parse_git_log,
    group_into_features,
    sort_commits_by_timestamp,
    detect_languages,
)
from .utils.json_writer import write_json_file
from .embeddings import EmbeddingEngine, EmbeddingResult
from .clustering import cluster_commits_semantic
from .classifier import ChangeTypeClassifier
from .similarity import compute_correlation_matrix, CorrelationScore
from .prompt_embedder import embed_prompts, PromptEmbedding
from .intent import reconstruct_session, detect_reprompts, classify_outcome, analyze_gaps
from .patterns import track_temporal_patterns, detect_file_couplings, generate_profile
from .patterns.profile_generator import generate_claude_context_md


fn emit_progress(stage: String, progress: Float32, message: String):
    """Print JSON progress line to stdout for the Rust bridge to consume."""
    var p = ScanProgress(stage, progress, message)
    print(p.to_json())


fn log_debug(msg: String, verbose: Bool):
    """Write a debug log line to stderr (won't interfere with stdout JSON protocol)."""
    if not verbose:
        return
    try:
        from python import Python

        var sys = Python.import_module("sys")
        sys.stderr.write("[mojo] " + msg + "\n")
        sys.stderr.flush()
    except:
        pass


fn compute_analytics(
    commits: List[CommitData], features: List[FeatureCluster]
) -> Analytics:
    """Compute project analytics from commits and features.

    Port of scan.rs:334-418 compute_analytics().
    """
    var analytics = Analytics()
    analytics.total_features = UInt32(len(features))

    var claude_count: UInt32 = 0

    # Track file and function frequencies
    var file_paths = List[String]()
    var file_counts = List[Int]()
    var func_names = List[String]()
    var func_counts = List[Int]()

    # Track week velocity
    var week_keys = List[String]()
    var week_features = List[UInt32]()
    var week_commits = List[UInt32]()

    for ci in range(len(commits)):
        # Change type totals
        analytics.add_change_type(commits[ci].change_type, 1)

        if commits[ci].is_claude_code:
            claude_count += 1

        for fi in range(len(commits[ci].files_changed)):
            # Track file frequency
            var found = False
            for pi in range(len(file_paths)):
                if file_paths[pi] == commits[ci].files_changed[fi].path:
                    file_counts[pi] += 1
                    found = True
                    break
            if not found:
                file_paths.append(commits[ci].files_changed[fi].path)
                file_counts.append(1)

            for fni in range(len(commits[ci].files_changed[fi].functions)):
                var func_name = commits[ci].files_changed[fi].functions[fni].name
                var fn_found = False
                for fci in range(len(func_names)):
                    if func_names[fci] == func_name:
                        func_counts[fci] += 1
                        fn_found = True
                        break
                if not fn_found:
                    func_names.append(func_name)
                    func_counts.append(1)

        # Week velocity: extract week from timestamp (YYYY-Www format)
        # Simple approach: extract date portion and compute ISO week
        var ts = commits[ci].timestamp
        if len(ts) >= 10:
            var _ = String(ts[:10])  # "2024-01-15" (date_part unused)
            # Use a simplified week key based on date
            # For proper ISO week, we'd need calendar math — approximate with YYYY-MM-Wn
            var year_month = String(ts[:7])  # "2024-01"
            if len(ts) >= 10:
                try:
                    var day = Int(String(ts[8:10]))
                    var week_num = (day - 1) // 7 + 1
                    var week_key = year_month + "-W" + String(week_num)

                    var wk_found = False
                    for wi in range(len(week_keys)):
                        if week_keys[wi] == week_key:
                            week_commits[wi] += 1
                            wk_found = True
                            break
                    if not wk_found:
                        week_keys.append(week_key)
                        week_features.append(0)
                        week_commits.append(1)
                except:
                    pass

    # Add feature counts to weeks
    for fi in range(len(features)):
        var ts = features[fi].time_start
        if len(ts) >= 10:
            var year_month = String(ts[:7])
            try:
                var day = Int(String(ts[8:10]))
                var week_num = (day - 1) // 7 + 1
                var week_key = year_month + "-W" + String(week_num)

                for wi in range(len(week_keys)):
                    if week_keys[wi] == week_key:
                        week_features[wi] += 1
                        break
            except:
                pass

    # Claude code percentage
    var total = Float32(len(commits))
    if total > 0:
        analytics.claude_code_commit_percentage = Float32(claude_count) / total
    else:
        analytics.claude_code_commit_percentage = 0.0

    # Most modified files (top 10, sorted by count descending)
    var sorted_fi = List[Int]()
    for i in range(len(file_paths)):
        sorted_fi.append(i)
    for i in range(len(sorted_fi)):
        var max_idx = i
        for j in range(i + 1, len(sorted_fi)):
            if file_counts[sorted_fi[j]] > file_counts[sorted_fi[max_idx]]:
                max_idx = j
        if max_idx != i:
            var tmp = sorted_fi[i]
            sorted_fi[i] = sorted_fi[max_idx]
            sorted_fi[max_idx] = tmp

    var file_limit = min(10, len(sorted_fi))
    for i in range(file_limit):
        analytics.most_modified_files.append(file_paths[sorted_fi[i]])

    # Most modified functions (top 10)
    var sorted_fn = List[Int]()
    for i in range(len(func_names)):
        sorted_fn.append(i)
    for i in range(len(sorted_fn)):
        var max_idx = i
        for j in range(i + 1, len(sorted_fn)):
            if func_counts[sorted_fn[j]] > func_counts[sorted_fn[max_idx]]:
                max_idx = j
        if max_idx != i:
            var tmp = sorted_fn[i]
            sorted_fn[i] = sorted_fn[max_idx]
            sorted_fn[max_idx] = tmp

    var fn_limit = min(10, len(sorted_fn))
    for i in range(fn_limit):
        analytics.most_modified_functions.append(func_names[sorted_fn[i]])

    analytics.total_functions_modified = UInt32(len(func_names))

    # Build velocity by week
    # Sort week keys
    var sorted_wk = List[Int]()
    for i in range(len(week_keys)):
        sorted_wk.append(i)
    for i in range(len(sorted_wk)):
        var min_idx = i
        for j in range(i + 1, len(sorted_wk)):
            if week_keys[sorted_wk[j]] < week_keys[sorted_wk[min_idx]]:
                min_idx = j
        if min_idx != i:
            var tmp = sorted_wk[i]
            sorted_wk[i] = sorted_wk[min_idx]
            sorted_wk[min_idx] = tmp

    for i in range(len(sorted_wk)):
        var idx = sorted_wk[i]
        var wv = WeekVelocity()
        wv.week = week_keys[idx]
        wv.features = week_features[idx]
        wv.commits = week_commits[idx]
        analytics.velocity_by_week.append(wv^)

    return analytics^


fn run() raises:
    var args = argv()

    if len(args) < 3:
        print(
            "Usage: codelens-engine --repo <path> --output <path>"
            " [--models-dir <path>] [--sessions-dir <path>]"
            " [--max-commits <N>] [--verbose|-v]"
        )
        return

    var repo_path = String("")
    var output_path = String("")
    var models_dir = String("./models")
    var sessions_dir = String("")
    var verbose = False
    var max_commits: Int = 2000

    var i = 1
    while i < len(args):
        if args[i] == "--repo" and i + 1 < len(args):
            repo_path = args[i + 1]
            i += 2
        elif args[i] == "--output" and i + 1 < len(args):
            output_path = args[i + 1]
            i += 2
        elif args[i] == "--models-dir" and i + 1 < len(args):
            models_dir = args[i + 1]
            i += 2
        elif args[i] == "--sessions-dir" and i + 1 < len(args):
            sessions_dir = args[i + 1]
            i += 2
        elif args[i] == "--max-commits" and i + 1 < len(args):
            try:
                max_commits = Int(args[i + 1])
            except:
                max_commits = 2000
            i += 2
        elif args[i] == "--verbose" or args[i] == "-v":
            verbose = True
            i += 1
        else:
            i += 1

    if repo_path == "" or output_path == "":
        print("Error: --repo and --output are required")
        return

    # === Phase 1: Foundation Pipeline ===

    emit_progress("init", 0.0, "CodeLens engine starting")
    log_debug("=== CodeLens Engine v0.1 ===", verbose)
    log_debug(
        "Args: repo="
        + repo_path
        + " output="
        + output_path
        + " models-dir="
        + models_dir
        + " max-commits="
        + String(max_commits),
        verbose,
    )
    if sessions_dir != "":
        log_debug("  sessions-dir=" + sessions_dir, verbose)

    # Stage 1: Parse git log (metadata + file stats in one subprocess call)
    emit_progress("parsing", 0.1, "Parsing git history...")
    var commits = parse_git_log(repo_path, max_commits)
    emit_progress("parsing", 0.3, "Parsed " + String(len(commits)) + " commits")

    # Log commit summary
    var claude_count_log: Int = 0
    for cli in range(len(commits)):
        if commits[cli].is_claude_code:
            claude_count_log += 1
    log_debug("--- Git Parsing ---", verbose)
    log_debug(
        "  Parsed " + String(len(commits)) + " commits (" + String(claude_count_log) + " by Claude Code)",
        verbose,
    )
    # Log first few commits
    var preview_count = min(5, len(commits))
    for pci in range(preview_count):
        log_debug(
            "  " + String(commits[pci].hash[:7]) + ' "' + commits[pci].subject + '" (' + String(commits[pci].timestamp[:10]) + ")",
            verbose,
        )

    # Log diff stats (file stats already parsed from git log --numstat)
    log_debug("--- File Stats ---", verbose)
    var total_files_changed: Int = 0
    var total_lines_added: Int = 0
    var total_lines_removed: Int = 0
    for dci in range(len(commits)):
        total_files_changed += len(commits[dci].files_changed)
        for dfi in range(len(commits[dci].files_changed)):
            total_lines_added += Int(commits[dci].files_changed[dfi].lines_added)
            total_lines_removed += Int(commits[dci].files_changed[dfi].lines_removed)
    log_debug("  Total files changed: " + String(total_files_changed), verbose)
    log_debug(
        "  Total lines: +" + String(total_lines_added) + " / -" + String(total_lines_removed),
        verbose,
    )

    # Stage 3: Sort commits (newest first)
    sort_commits_by_timestamp(commits)

    # Log date range after sort
    log_debug("--- Sorting ---", verbose)
    if len(commits) > 0:
        log_debug(
            "  Date range: " + String(commits[len(commits) - 1].timestamp[:10]) + " -> " + String(commits[0].timestamp[:10]),
            verbose,
        )

    # Stage 4: Group into features (4-hour time window)
    emit_progress("clustering", 0.55, "Grouping commits into features...")
    var features = group_into_features(commits)
    emit_progress(
        "clustering",
        0.65,
        "Created " + String(len(features)) + " feature clusters",
    )

    # Log feature clusters
    log_debug("--- Feature Clustering (4h window) ---", verbose)
    log_debug("  Created " + String(len(features)) + " clusters:", verbose)
    var cluster_preview = min(5, len(features))
    for fci in range(cluster_preview):
        log_debug(
            "    #"
            + String(features[fci].cluster_id)
            + ": "
            + String(len(features[fci].commit_hashes))
            + ' commits — "'
            + features[fci].auto_label
            + '"',
            verbose,
        )
    if len(features) > 5:
        log_debug("    ... (" + String(len(features) - 5) + " more)", verbose)

    # Stage 5: Detect languages
    var languages = detect_languages(commits)

    # Log languages
    log_debug("--- Languages ---", verbose)
    var lang_str = String("")
    for li in range(len(languages)):
        if li > 0:
            lang_str += ", "
        lang_str += languages[li]
    log_debug("  " + lang_str, verbose)

    # Stage 6: Compute analytics
    emit_progress("analytics", 0.7, "Computing analytics...")
    var analytics = compute_analytics(commits, features)

    # Log analytics summary
    log_debug("--- Analytics ---", verbose)
    log_debug("  Total features: " + String(analytics.total_features), verbose)
    log_debug(
        "  Claude Code %: " + String(Int(analytics.claude_code_commit_percentage * 100)) + "%",
        verbose,
    )
    var top_files_preview = min(3, len(analytics.most_modified_files))
    if top_files_preview > 0:
        log_debug("  Top files:", verbose)
        for tfi in range(top_files_preview):
            log_debug("    " + analytics.most_modified_files[tfi], verbose)

    # Build date range
    var date_range = DateRange()
    if len(commits) > 0:
        # Commits are sorted newest-first
        date_range.start = commits[len(commits) - 1].timestamp
        date_range.end = commits[0].timestamp

    # Build repository info
    # Extract repo name from path (last component)
    var last_slash = -1
    for ci in range(len(repo_path)):
        if repo_path.as_bytes()[ci] == UInt8(ord("/")):
            last_slash = ci
    var repo_name: String
    if last_slash >= 0 and last_slash < len(repo_path) - 1:
        repo_name = String(repo_path[last_slash + 1 :])
    else:
        repo_name = repo_path

    var repository = RepositoryInfo()
    repository.path = repo_path
    repository.name = repo_name
    repository.total_commits = UInt32(len(commits))
    repository.date_range = date_range^
    repository.languages_detected = languages^

    # === Phase 2: ML Pipeline ===
    # Try to load models and use ML-based clustering + classification.
    # Falls back to Phase 1 heuristics if models not available.
    var use_ml = False
    var embedding_engine = EmbeddingEngine(models_dir)
    var embeddings = List[EmbeddingResult]()
    var classifier = ChangeTypeClassifier()

    try:
        emit_progress("ml_init", 0.7, "Loading ML models...")
        log_debug("--- ML Pipeline ---", verbose)
        log_debug("  Model path: " + models_dir, verbose)
        var model_loaded = embedding_engine.load_model()
        log_debug("  Model loaded: " + String(model_loaded), verbose)

        if model_loaded:
            use_ml = True

            # Generate embeddings
            emit_progress("embeddings", 0.72, "Generating CodeBERT embeddings...")
            embeddings = embedding_engine.generate_embeddings(commits)
            emit_progress(
                "embeddings",
                0.78,
                "Generated "
                + String(len(embeddings))
                + " embeddings",
            )

            # Log embedding stats
            log_debug("  Generated " + String(len(embeddings)) + " embeddings", verbose)
            if len(embeddings) > 0 and len(embeddings[0].vector) > 0:
                var norm_sum: Float32 = 0.0
                for eni in range(len(embeddings)):
                    var norm: Float32 = 0.0
                    for vni in range(len(embeddings[eni].vector)):
                        norm += embeddings[eni].vector[vni] * embeddings[eni].vector[vni]
                    # Approximate sqrt via Newton's method
                    if norm > 0:
                        var x = norm
                        for _ in range(10):
                            x = (x + norm / x) * 0.5
                        norm_sum += x
                log_debug(
                    "  Avg embedding norm: " + _json_f32(norm_sum / Float32(len(embeddings))),
                    verbose,
                )

            # Semantic clustering (replaces time-window heuristic)
            emit_progress("clustering_ml", 0.8, "Running DBSCAN semantic clustering...")
            log_debug("--- DBSCAN Clustering ---", verbose)
            log_debug("  eps=0.3 min_samples=2", verbose)
            var semantic_features = cluster_commits_semantic(
                commits, embeddings, eps=0.3, min_samples=2
            )

            if len(semantic_features) > 0:
                # Count noise points (commits not in any semantic cluster)
                var noise_count: Int = 0
                for nci in range(len(commits)):
                    var in_cluster = False
                    for sfi in range(len(semantic_features)):
                        for shi in range(len(semantic_features[sfi].commit_hashes)):
                            if semantic_features[sfi].commit_hashes[shi] == commits[nci].hash:
                                in_cluster = True
                                break
                        if in_cluster:
                            break
                    if not in_cluster:
                        noise_count += 1

                features = semantic_features^
                emit_progress(
                    "clustering_ml",
                    0.82,
                    "Created "
                    + String(len(features))
                    + " semantic feature clusters",
                )

                log_debug(
                    "  Clusters: " + String(len(features)) + " (" + String(noise_count) + " noise points)",
                    verbose,
                )
                # Log cluster sizes
                var sizes_str = String("")
                var sizes_preview = min(10, len(features))
                for csi in range(sizes_preview):
                    if csi > 0:
                        sizes_str += ", "
                    sizes_str += String(len(features[csi].commit_hashes))
                log_debug("  Cluster sizes: [" + sizes_str + "]", verbose)

            # ML-based classification (replaces keyword heuristic)
            emit_progress("classification", 0.83, "Loading classifier weights...")
            var _loaded = classifier.load_weights(models_dir)
            if classifier.weights_loaded:
                emit_progress("classification", 0.85, "Classifying change types with ML...")
                # Build subjects list
                var subjects = List[String]()
                for ci in range(len(commits)):
                    subjects.append(commits[ci].subject)

                # Find matching embeddings for each commit
                for ci in range(len(commits)):
                    # Find embedding for this commit
                    for ei in range(len(embeddings)):
                        if embeddings[ei].commit_hash == commits[ci].hash:
                            var result = classifier.classify(
                                embeddings[ei].vector,
                                commits[ci].subject.lower(),
                            )
                            commits[ci].change_type = result.predicted_class
                            commits[ci].change_type_confidence = result.confidence
                            break

                emit_progress("classification", 0.87, "Change types classified with ML")

                # Log classification distribution
                log_debug("--- Classification ---", verbose)
                var ct_names = List[String]()
                var ct_counts = List[Int]()
                var conf_sum: Float32 = 0.0
                for cci in range(len(commits)):
                    conf_sum += commits[cci].change_type_confidence
                    var ct_found = False
                    for cti in range(len(ct_names)):
                        if ct_names[cti] == commits[cci].change_type:
                            ct_counts[cti] += 1
                            ct_found = True
                            break
                    if not ct_found:
                        ct_names.append(commits[cci].change_type)
                        ct_counts.append(1)
                var dist_str = String("")
                for dsi in range(len(ct_names)):
                    if dsi > 0:
                        dist_str += ", "
                    dist_str += ct_names[dsi] + "=" + String(ct_counts[dsi])
                log_debug("  Distribution: " + dist_str, verbose)
                if len(commits) > 0:
                    log_debug(
                        "  Avg confidence: " + _json_f32(conf_sum / Float32(len(commits))),
                        verbose,
                    )

        else:
            emit_progress(
                "ml_init",
                0.7,
                "ML models not available. Using heuristic pipeline.",
            )
            log_debug("  ML models not available, using heuristic pipeline", verbose)

    except e:
        emit_progress(
            "ml_init",
            0.7,
            "ML pipeline error: " + String(e) + ". Falling back to heuristics.",
        )
        log_debug("  ML pipeline error: " + String(e), verbose)
        use_ml = False

    # Recompute analytics with potentially updated features/classifications
    analytics = compute_analytics(commits, features)

    # === Phase 4: Prompt-to-Code Correlation ===
    # If ML models are loaded and sessions_dir provided, embed prompts and
    # compute semantic similarity matrix.
    if use_ml and sessions_dir != "":
        try:
            emit_progress("correlation", 0.88, "Loading prompt sessions for correlation...")

            from python import Python

            var os = Python.import_module("os")
            var json_mod = Python.import_module("json")

            # Read JSONL session files from sessions_dir
            var prompt_texts = List[String]()
            var prompt_session_ids = List[String]()

            if os.path.isdir(sessions_dir):
                var files = os.listdir(sessions_dir)
                for fi in range(len(files)):
                    var fname = String(files[fi])
                    if fname.endswith(".jsonl"):
                        var session_id = String(fname[: len(fname) - 6])  # strip .jsonl
                        var fpath = String(sessions_dir) + "/" + fname
                        var f = Python.import_module("builtins").open(fpath, "r")
                        for line in f:
                            var line_s_raw = String(line)
                            var line_s = String(line_s_raw.strip())
                            if line_s == "":
                                continue
                            try:
                                var obj = json_mod.loads(line_s)
                                if String(obj.get("type", "")) == "user":
                                    var empty_dict = Python.import_module("builtins").dict()
                                    var msg = obj.get("message", empty_dict)
                                    var content = msg.get("content", "")
                                    if Python.import_module("builtins").isinstance(
                                        content, Python.import_module("builtins").str
                                    ):
                                        var text_raw = String(content)
                                        var text = String(text_raw.strip())
                                        if text != "":
                                            prompt_texts.append(text)
                                            prompt_session_ids.append(session_id)
                            except:
                                pass
                        f.close()

            if len(prompt_texts) > 0 and len(embeddings) > 0:
                emit_progress(
                    "correlation",
                    0.89,
                    "Embedding " + String(len(prompt_texts)) + " prompts...",
                )

                var prompt_embs = embed_prompts(
                    embedding_engine, prompt_texts, prompt_session_ids
                )

                if len(prompt_embs) > 0:
                    # Build data for correlation matrix
                    var p_vectors = List[List[Float32]]()
                    var c_vectors = List[List[Float32]]()
                    var c_hashes = List[String]()
                    var p_files = List[List[String]]()
                    var c_files_list = List[List[String]]()
                    var p_timestamps = List[Int]()
                    var c_timestamps = List[Int]()
                    var p_end_timestamps = List[Int]()
                    var is_claude = List[Bool]()

                    for pi2 in range(len(prompt_embs)):
                        p_vectors.append(prompt_embs[pi2].vector.copy())
                        p_files.append(List[String]())
                        p_timestamps.append(0)
                        p_end_timestamps.append(0)

                    for ei2 in range(len(embeddings)):
                        c_vectors.append(embeddings[ei2].vector.copy())
                        c_hashes.append(embeddings[ei2].commit_hash)
                        # Find commit data for files and timestamps
                        for ci2 in range(len(commits)):
                            if commits[ci2].hash == embeddings[ei2].commit_hash:
                                var cfiles = List[String]()
                                for cfi in range(len(commits[ci2].files_changed)):
                                    cfiles.append(
                                        commits[ci2].files_changed[cfi].path
                                    )
                                c_files_list.append(cfiles^)
                                c_timestamps.append(0)  # Simplified
                                is_claude.append(commits[ci2].is_claude_code)
                                break

                    var scores = compute_correlation_matrix(
                        p_vectors,
                        c_vectors,
                        c_hashes,
                        p_files,
                        c_files_list,
                        p_timestamps,
                        c_timestamps,
                        p_end_timestamps,
                        is_claude,
                        threshold=0.4,
                    )

                    emit_progress(
                        "correlation",
                        0.92,
                        "Found "
                        + String(len(scores))
                        + " prompt-commit correlations",
                    )

                    # Log correlation details
                    log_debug("--- Prompt Correlation ---", verbose)
                    log_debug(
                        "  Sessions: " + String(len(prompt_session_ids)) + ", Prompts: " + String(len(prompt_texts)),
                        verbose,
                    )
                    log_debug("  Correlations found: " + String(len(scores)), verbose)
                    if len(scores) > 0:
                        var avg_score: Float32 = 0.0
                        for sci in range(len(scores)):
                            avg_score += scores[sci].semantic_score
                        log_debug(
                            "  Avg similarity: " + _json_f32(avg_score / Float32(len(scores))),
                            verbose,
                        )

        except e:
            emit_progress(
                "correlation",
                0.88,
                "Prompt correlation error: " + String(e),
            )
            log_debug("  Correlation error: " + String(e), verbose)

    # === Phase 5: Intent Analysis ===
    if sessions_dir != "":
        try:
            emit_progress("intent", 0.93, "Analyzing developer intent...")

            from python import Python

            var os_mod = Python.import_module("os")
            if os_mod.path.isdir(sessions_dir):
                var session_files = os_mod.listdir(sessions_dir)
                var session_count: Int = 0
                for sfi in range(len(session_files)):
                    var fname = String(session_files[sfi])
                    if fname.endswith(".jsonl"):
                        var sid = String(fname[: len(fname) - 6])
                        var spath = String(sessions_dir) + "/" + fname
                        try:
                            var recon = reconstruct_session(spath, sid)
                            session_count += 1
                        except:
                            pass
                emit_progress(
                    "intent",
                    0.94,
                    "Analyzed " + String(session_count) + " sessions",
                )

                # Log intent summary
                log_debug("--- Intent Analysis ---", verbose)
                log_debug("  Sessions analyzed: " + String(session_count), verbose)
        except e:
            emit_progress("intent", 0.93, "Intent analysis error: " + String(e))
            log_debug("  Intent analysis error: " + String(e), verbose)

    # === Phase 6: Pattern Detection ===
    try:
        emit_progress("patterns", 0.95, "Detecting development patterns...")

        # Temporal patterns
        var temporal = track_temporal_patterns(commits)

        # File couplings
        var couplings = detect_file_couplings(commits, min_count=3)

        # Generate developer profile
        var profile = generate_profile(commits, temporal, couplings)

        # Write profile JSON alongside output
        from python import Python

        var os_p6 = Python.import_module("os")
        var output_dir = String(os_p6.path.dirname(String(output_path)))
        if output_dir != "":
            var profile_path = output_dir + "/developer_profile.json"
            var builtins_p6 = Python.import_module("builtins")
            var pf = builtins_p6.open(profile_path, "w", encoding="utf-8")
            pf.write(profile.to_json())
            pf.close()

            # Write claude_context.md
            var context_path = output_dir + "/claude_context.md"
            var context_md = generate_claude_context_md(profile)
            var cf = builtins_p6.open(context_path, "w", encoding="utf-8")
            cf.write(String(context_md))
            cf.close()

        emit_progress(
            "patterns",
            0.97,
            "Found "
            + String(len(couplings))
            + " file couplings, peak hours: "
            + String(len(temporal.peak_hours)),
        )

        # Log pattern details
        log_debug("--- Pattern Detection ---", verbose)
        var peak_str = String("")
        for phi in range(len(temporal.peak_hours)):
            if phi > 0:
                peak_str += ", "
            peak_str += String(temporal.peak_hours[phi]) + ":00"
        log_debug("  Peak hours: " + peak_str, verbose)
        log_debug("  File couplings: " + String(len(couplings)), verbose)
    except e:
        emit_progress("patterns", 0.95, "Pattern detection error: " + String(e))
        log_debug("  Pattern detection error: " + String(e), verbose)

    # Build final ProjectData
    var project_data = ProjectData()
    project_data.repository = repository^
    project_data.commits = commits^
    project_data.features = features^
    project_data.analytics = analytics^

    # Write output JSON
    emit_progress("output", 0.9, "Writing output JSON...")
    write_json_file(project_data, output_path)

    # Log output file size
    log_debug("--- Output ---", verbose)
    try:
        from python import Python

        var os_out = Python.import_module("os")
        var file_size = Int(py=os_out.path.getsize(String(output_path)))
        if file_size > 1024:
            log_debug("  Wrote " + output_path + " (" + String(file_size // 1024) + " KB)", verbose)
        else:
            log_debug("  Wrote " + output_path + " (" + String(file_size) + " bytes)", verbose)
    except:
        log_debug("  Wrote " + output_path, verbose)

    emit_progress(
        "complete",
        1.0,
        "Analysis complete. "
        + String(len(project_data.commits))
        + " commits, "
        + String(len(project_data.features))
        + " features.",
    )
