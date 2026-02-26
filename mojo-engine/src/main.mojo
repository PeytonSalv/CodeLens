from sys import argv


fn print_progress(stage: String, progress: Int, message: String):
    """Print JSON progress line to stdout for Tauri to consume."""
    var p: String
    if progress == 0:
        p = "0.0"
    else:
        p = "1.0"
    print(
        '{"stage": "'
        + stage
        + '", "progress": '
        + p
        + ', "message": "'
        + message
        + '"}'
    )


fn main():
    var args = argv()

    if len(args) < 3:
        print(
            "Usage: codelens-engine --repo <path> --output <path>"
            " [--models-dir <path>]"
        )
        return

    var repo_path = String("")
    var output_path = String("")
    var models_dir = String("./models")

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
        else:
            i += 1

    if repo_path == "" or output_path == "":
        print("Error: --repo and --output are required")
        return

    print_progress("init", 0, "CodeLens engine starting")
    print_progress("init", 1, "Repo: " + repo_path)

    # Pipeline stages will be implemented in subsequent modules:
    # 1. git_parser.mojo    - Parse git history
    # 2. diff_extractor.mojo - Extract function-level changes
    # 3. prompt_detector.mojo - Detect Claude Code sessions
    # 4. embeddings.mojo     - Generate code embeddings via MAX Engine
    # 5. clustering.mojo     - Cluster commits into features
    # 6. classifier.mojo     - Classify change types
    # 7. similarity.mojo     - Score prompt-to-output similarity

    print_progress("complete", 1, "Engine initialized. Pipeline modules pending.")
