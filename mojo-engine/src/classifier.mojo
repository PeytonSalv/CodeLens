"""Multi-class classifier for commit change types using CodeBERT embeddings.

Replaces keyword-based classify_change_type() with a learned classifier.
Uses a simple linear head on 768-dim embeddings -> 6 classes.
Falls back to keyword heuristic if model not available.
"""

from math import exp
from .embeddings import EmbeddingResult, EMBEDDING_DIM
from .git_parser import classify_change_type


comptime NUM_CLASSES = 7


fn _class_names() -> List[String]:
    """Return the list of class names for classification."""
    var names = List[String]()
    names.append("new_feature")
    names.append("bug_fix")
    names.append("refactor")
    names.append("performance")
    names.append("test")
    names.append("documentation")
    names.append("style")
    return names^


struct ClassificationResult(Copyable, Movable):
    """Classification result with confidence scores."""

    var predicted_class: String
    var confidence: Float32
    var scores: List[Float32]  # one per class

    fn __init__(out self):
        self.predicted_class = String("new_feature")
        self.confidence = 0.7
        self.scores = List[Float32]()

    fn __init__(out self, *, copy: Self):
        self.predicted_class = copy.predicted_class
        self.confidence = copy.confidence
        self.scores = copy.scores.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.predicted_class = take.predicted_class^
        self.confidence = take.confidence
        self.scores = take.scores^


struct ChangeTypeClassifier(Copyable, Movable):
    """Linear classifier head on CodeBERT embeddings.

    Weights should be loaded from a pre-trained model file.
    Falls back to keyword heuristic if weights not available.
    """

    var weights_loaded: Bool
    # Weight matrix: NUM_CLASSES x EMBEDDING_DIM (stored flat)
    var weights: List[Float32]
    # Bias vector: NUM_CLASSES
    var biases: List[Float32]

    fn __init__(out self):
        self.weights_loaded = False
        self.weights = List[Float32]()
        self.biases = List[Float32]()

    fn __init__(out self, *, copy: Self):
        self.weights_loaded = copy.weights_loaded
        self.weights = copy.weights.copy()
        self.biases = copy.biases.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.weights_loaded = take.weights_loaded
        self.weights = take.weights^
        self.biases = take.biases^

    fn load_weights(mut self, models_dir: String) raises -> Bool:
        """Load pre-trained classifier weights from file.

        Expects: <models_dir>/classifier_weights.bin
        Format: float32 array of (NUM_CLASSES * EMBEDDING_DIM) weights + NUM_CLASSES biases
        """
        from python import Python

        var os = Python.import_module("os")
        var np = Python.import_module("numpy")
        var weights_path = String(models_dir) + "/classifier_weights.npz"

        if not os.path.exists(weights_path):
            self.weights_loaded = False
            return False

        try:
            var data = np.load(weights_path)
            var w = data["weights"]  # shape: (NUM_CLASSES, EMBEDDING_DIM)
            var b = data["biases"]  # shape: (NUM_CLASSES,)

            self.weights = List[Float32]()
            for i in range(NUM_CLASSES):
                for j in range(EMBEDDING_DIM):
                    self.weights.append(Float32(py=w[i][j]))

            self.biases = List[Float32]()
            for i in range(NUM_CLASSES):
                self.biases.append(Float32(py=b[i]))

            self.weights_loaded = True
            return True
        except:
            self.weights_loaded = False
            return False

    fn classify(
        self, embedding: List[Float32], subject: String
    ) -> ClassificationResult:
        """Classify a commit given its embedding vector.

        Falls back to keyword heuristic if weights not loaded.
        """
        var result = ClassificationResult()

        if not self.weights_loaded or len(embedding) != EMBEDDING_DIM:
            # Fallback to keyword heuristic
            result.predicted_class = classify_change_type(subject.lower())
            result.confidence = 0.7
            return result^

        # Linear layer: scores = W @ embedding + b
        var logits = List[Float32]()
        for c in range(NUM_CLASSES):
            var score: Float32 = self.biases[c]
            var offset = c * EMBEDDING_DIM
            for d in range(EMBEDDING_DIM):
                score += self.weights[offset + d] * embedding[d]
            logits.append(score)

        # Softmax
        var max_logit: Float32 = logits[0]
        for c in range(1, NUM_CLASSES):
            if logits[c] > max_logit:
                max_logit = logits[c]

        var exp_sum: Float32 = 0.0
        var probs = List[Float32]()
        for c in range(NUM_CLASSES):
            var e = exp(logits[c] - max_logit)
            probs.append(e)
            exp_sum += e

        for c in range(NUM_CLASSES):
            probs[c] /= exp_sum

        # Find argmax
        var best_class: Int = 0
        var best_prob: Float32 = probs[0]
        for c in range(1, NUM_CLASSES):
            if probs[c] > best_prob:
                best_prob = probs[c]
                best_class = c

        var class_names = _class_names()
        result.predicted_class = class_names[best_class]
        result.confidence = best_prob
        result.scores = probs^
        return result^

    fn classify_batch(
        self,
        embeddings: List[EmbeddingResult],
        subjects: List[String],
    ) -> List[ClassificationResult]:
        """Classify a batch of commits."""
        var results = List[ClassificationResult]()
        for i in range(len(embeddings)):
            var subject = String("")
            if i < len(subjects):
                subject = subjects[i]
            results.append(self.classify(embeddings[i].vector, subject))
        return results^
