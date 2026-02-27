"""Embeddings module — loads CodeBERT ONNX via MAX Engine for 768-dim embeddings.

Generates vector embeddings from commit diff text and prompt text.
Falls back gracefully if models are not available.
"""

from .types import CommitData


comptime EMBEDDING_DIM = 768
comptime MAX_TOKENS = 512


struct EmbeddingResult(Copyable, Movable):
    """A single embedding vector with metadata."""

    var commit_hash: String
    var vector: List[Float32]
    var text_preview: String  # first 100 chars of input text

    fn __init__(out self):
        self.commit_hash = String("")
        self.vector = List[Float32]()
        self.text_preview = String("")

    fn __init__(out self, *, copy: Self):
        self.commit_hash = copy.commit_hash
        self.vector = copy.vector.copy()
        self.text_preview = copy.text_preview

    fn __moveinit__(out self, deinit take: Self):
        self.commit_hash = take.commit_hash^
        self.vector = take.vector^
        self.text_preview = take.text_preview^


struct EmbeddingEngine(Copyable, Movable):
    """Manages CodeBERT model loading and inference via MAX Engine."""

    var models_dir: String
    var model_loaded: Bool

    fn __init__(out self, models_dir: String):
        self.models_dir = models_dir
        self.model_loaded = False

    fn __init__(out self, *, copy: Self):
        self.models_dir = copy.models_dir
        self.model_loaded = copy.model_loaded

    fn __moveinit__(out self, deinit take: Self):
        self.models_dir = take.models_dir^
        self.model_loaded = take.model_loaded

    fn load_model(mut self) raises -> Bool:
        """Attempt to load CodeBERT ONNX model via MAX Engine.

        Returns True if model loaded successfully, False otherwise.
        Model should be at: <models_dir>/codebert.onnx
        """
        from python import Python

        var os = Python.import_module("os")
        var model_path = String(self.models_dir) + "/codebert.onnx"

        if not os.path.exists(model_path):
            print(
                '{"stage": "embeddings", "progress": 0.0, "message":'
                ' "CodeBERT model not found at '
                + model_path
                + '. Using heuristic fallback."}'
            )
            self.model_loaded = False
            return False

        try:
            # Try to load via MAX Engine ONNX runtime
            var max_engine = Python.import_module("max.engine")
            var session = max_engine.InferenceSession()
            var model = session.load(model_path)
            self.model_loaded = True
            print(
                '{"stage": "embeddings", "progress": 0.1, "message":'
                ' "CodeBERT model loaded successfully via MAX Engine."}'
            )
            return True
        except e:
            print(
                '{"stage": "embeddings", "progress": 0.0, "message":'
                ' "MAX Engine load failed: '
                + String(e)
                + '. Using heuristic fallback."}'
            )
            self.model_loaded = False
            return False

    fn generate_embeddings(
        self, commits: List[CommitData]
    ) raises -> List[EmbeddingResult]:
        """Generate embeddings for all commits from their diff text.

        If model is loaded, uses CodeBERT inference.
        Otherwise, returns empty list (caller falls back to heuristics).
        """
        if not self.model_loaded:
            return List[EmbeddingResult]()

        from python import Python

        var results = List[EmbeddingResult]()

        var np = Python.import_module("numpy")
        var max_engine = Python.import_module("max.engine")
        var transformers = Python.import_module("transformers")

        # Load tokenizer
        var tokenizer = transformers.AutoTokenizer.from_pretrained(
            "microsoft/codebert-base"
        )

        var session = max_engine.InferenceSession()
        var model_path = String(self.models_dir) + "/codebert.onnx"
        var model = session.load(model_path)

        for i in range(len(commits)):
            # Build input text from file changes
            var input_text = commits[i].subject + "\n"
            for fi in range(len(commits[i].files_changed)):
                input_text += commits[i].files_changed[fi].path + " "
                input_text += (
                    "+"
                    + String(Int(commits[i].files_changed[fi].lines_added))
                    + "/-"
                    + String(Int(commits[i].files_changed[fi].lines_removed))
                    + "\n"
                )

            # Tokenize (first MAX_TOKENS tokens)
            var encoded = tokenizer(
                String(input_text),
                max_length=MAX_TOKENS,
                truncation=True,
                padding="max_length",
                return_tensors="np",
            )

            # Run inference
            var input_ids = encoded["input_ids"]
            var attention_mask = encoded["attention_mask"]

            var outputs = model.execute(
                input_ids=input_ids,
                attention_mask=attention_mask,
            )

            # Extract [CLS] token embedding (first token, 768-dim)
            var last_hidden = outputs[0]
            var cls_embedding = last_hidden[0][0]

            var result = EmbeddingResult()
            result.commit_hash = commits[i].hash
            if len(input_text) > 100:
                result.text_preview = String(input_text[:100])
            else:
                result.text_preview = input_text

            # Convert numpy array to Mojo list
            for d in range(EMBEDDING_DIM):
                result.vector.append(Float32(py=cls_embedding[d]))

            results.append(result^)

        return results^

    fn embed_text(self, text: String) raises -> List[Float32]:
        """Embed a single text string and return its 768-dim vector.

        Used for prompt embedding in Phase 4.
        """
        if not self.model_loaded:
            return List[Float32]()

        from python import Python

        var np = Python.import_module("numpy")
        var max_engine = Python.import_module("max.engine")
        var transformers = Python.import_module("transformers")

        var tokenizer = transformers.AutoTokenizer.from_pretrained(
            "microsoft/codebert-base"
        )
        var session = max_engine.InferenceSession()
        var model_path = String(self.models_dir) + "/codebert.onnx"
        var model = session.load(model_path)

        var encoded = tokenizer(
            String(text),
            max_length=MAX_TOKENS,
            truncation=True,
            padding="max_length",
            return_tensors="np",
        )

        var outputs = model.execute(
            input_ids=encoded["input_ids"],
            attention_mask=encoded["attention_mask"],
        )

        var cls_embedding = outputs[0][0][0]
        var vector = List[Float32]()
        for d in range(EMBEDDING_DIM):
            vector.append(Float32(py=cls_embedding[d]))

        return vector^
