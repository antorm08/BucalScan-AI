"""
Diagnostic script: loads the ONNX model and reports its metadata + a dummy inference.
Run from the backend/ directory: python scripts/verify_model.py
"""
import os
import sys
from pathlib import Path

import numpy as np

os.environ.setdefault("JWT_SECRET", "verify-model-script-only")
BACKEND_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND_DIR))

from config import settings

try:
    import onnxruntime as ort
except ImportError:
    print("ERROR: onnxruntime is not installed. Run: pip install onnxruntime")
    sys.exit(1)

MODEL_PATH = Path(settings.model_path)

EXPECTED_INPUT_SHAPE = (1, 3, 224, 224)
EXPECTED_DTYPE = "float32"
CLASSES = ["benign", "malignant"]


def inspect_model(session: ort.InferenceSession) -> None:
    print("\n=== MODEL INPUTS ===")
    for inp in session.get_inputs():
        print(f"  name  : {inp.name}")
        print(f"  shape : {inp.shape}")
        print(f"  dtype : {inp.type}")

    print("\n=== MODEL OUTPUTS ===")
    for out in session.get_outputs():
        print(f"  name  : {out.name}")
        print(f"  shape : {out.shape}")
        print(f"  dtype : {out.type}")


def validate_shapes(session: ort.InferenceSession) -> bool:
    inp = session.get_inputs()[0]
    actual_shape = tuple(inp.shape)
    ok = True

    if actual_shape != EXPECTED_INPUT_SHAPE:
        # Dynamic batch dimension is acceptable: [None/batch, 3, 224, 224]
        spatial_ok = actual_shape[1:] == EXPECTED_INPUT_SHAPE[1:]
        if not spatial_ok:
            print(f"\nWARNING: Unexpected input shape {actual_shape}, expected {EXPECTED_INPUT_SHAPE}")
            ok = False
        else:
            print(f"\nOK: Dynamic batch dimension detected; spatial shape matches {EXPECTED_INPUT_SHAPE[1:]}")
    else:
        print(f"\nOK: Input shape matches expected {EXPECTED_INPUT_SHAPE}")

    return ok


def run_dummy_inference(session: ort.InferenceSession) -> None:
    input_name = session.get_inputs()[0].name
    dummy = np.random.rand(*EXPECTED_INPUT_SHAPE).astype(np.float32)

    print("\n=== DUMMY INFERENCE ===")
    print(f"  Input tensor shape : {dummy.shape}, dtype: {dummy.dtype}")

    outputs = session.run(None, {input_name: dummy})
    raw = np.asarray(outputs[0], dtype=np.float32).squeeze()
    values = np.atleast_1d(raw)

    print(f"  Raw output shape   : {values.shape}")
    print(f"  Raw output values  : {values}")

    if values.shape[0] == 1:
        malignant_prob = float(1.0 / (1.0 + np.exp(-values[0])))
        probs = {"benign": 1.0 - malignant_prob, "malignant": malignant_prob}
        predicted = CLASSES[1 if malignant_prob >= 0.5 else 0]
        print(f"  Output mode        : binary sigmoid (1 logit)")
    elif values.shape[0] == len(CLASSES):
        shifted = values - np.max(values)
        softmax = np.exp(shifted) / np.sum(np.exp(shifted))
        probs = {c: float(softmax[i]) for i, c in enumerate(CLASSES)}
        predicted = CLASSES[int(np.argmax(softmax))]
        print(f"  Output mode        : softmax ({len(CLASSES)} logits)")
    else:
        print(f"  ERROR: Unexpected output size {values.shape[0]} — not 1 or {len(CLASSES)}")
        return

    print(f"  Probabilities      : {probs}")
    print(f"  Prediction (dummy) : {predicted}")


def main() -> None:
    print(f"Model path: {MODEL_PATH}")
    print(f"Model architecture: {settings.model_architecture}")
    print(f"Model version: {settings.model_version}")

    if not MODEL_PATH.exists():
        print(f"ERROR: Model file not found at {MODEL_PATH}")
        sys.exit(1)

    print("Loading model...")
    session = ort.InferenceSession(str(MODEL_PATH), providers=["CPUExecutionProvider"])
    print("Model loaded successfully.")

    inspect_model(session)
    validate_shapes(session)
    run_dummy_inference(session)

    print("\nDone.")


if __name__ == "__main__":
    main()
