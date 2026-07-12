from pathlib import Path

import numpy as np
try:
    import onnxruntime as ort
except ImportError:  # pragma: no cover - dependency may be missing locally
    ort = None
from PIL import Image

from config import settings

CLASSES = ["benign", "malignant"]

class OralLesionClassifier:
    def __init__(self, model_path: str = None):
        self.model = None
        self.input_name = None
        self.model_path = Path(model_path or settings.model_path)

        if self.model_path.exists():
            self.load_model(str(self.model_path))

    def load_model(self, model_path: str):
        if ort is None:
            raise RuntimeError("onnxruntime is not installed. Add it to the backend environment to load the model.")

        self.model_path = Path(model_path)
        self.model = ort.InferenceSession(str(self.model_path), providers=["CPUExecutionProvider"])
        self.input_name = self.model.get_inputs()[0].name

    def validate_contract(self) -> None:
        if self.model is None:
            raise RuntimeError("Model is not loaded.")
        inputs = self.model.get_inputs()
        outputs = self.model.get_outputs()
        if len(inputs) != 1 or not outputs:
            raise RuntimeError("Expected one input and at least one output.")
        shape = tuple(inputs[0].shape)
        if len(shape) != 4 or tuple(shape[1:]) != (3, 224, 224):
            raise RuntimeError("Expected model input shape [batch, 3, 224, 224].")
        if inputs[0].type != "tensor(float)":
            raise RuntimeError("Expected float32 model input.")
        output_shape = tuple(outputs[0].shape)
        if not output_shape or output_shape[-1] not in (1, 2):
            raise RuntimeError("Expected one binary logit or two class logits.")

    def _preprocess(self, image: Image.Image) -> np.ndarray:
        """Convert a PIL image to a normalized float32 tensor [1, 3, 224, 224].

        Pipeline:
          1. convert("RGB")          – discard alpha, enforce 3 channels
          2. resize((224, 224))      – PIL default resampling (BILINEAR)
          3. / 255.0                 – scale to [0.0, 1.0]
          4. - mean / std            – ImageNet normalization per channel
                                       mean=[0.485, 0.456, 0.406]
                                       std =[0.229, 0.224, 0.225]
          5. transpose (2,0,1)       – HWC → CHW
          6. expand_dims(axis=0)     – add batch dim → [1, 3, 224, 224]
        """
        image = image.convert("RGB").resize((224, 224))
        image_array = np.asarray(image, dtype=np.float32) / 255.0

        mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
        std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
        image_array = (image_array - mean) / std

        image_array = np.transpose(image_array, (2, 0, 1))
        return np.expand_dims(image_array, axis=0)

    def predict(self, image: Image.Image) -> dict:
        if self.model is None or self.input_name is None:
            raise RuntimeError(
                f"Model file not loaded. Place the ONNX model at {self.model_path} or set MODEL_PATH in backend/.env."
            )

        image_tensor = self._preprocess(image)
        outputs = self.model.run(None, {self.input_name: image_tensor})
        raw_output = np.asarray(outputs[0], dtype=np.float32).squeeze()
        values = np.atleast_1d(raw_output)

        if values.shape[0] == 1:
            malignant_probability = float(1.0 / (1.0 + np.exp(-values[0])))
            probabilities = {
                "benign": float(1.0 - malignant_probability),
                "malignant": malignant_probability,
            }
            predicted_index = 1 if malignant_probability >= 0.5 else 0
            confidence = probabilities[CLASSES[predicted_index]]
        elif values.shape[0] == len(CLASSES):
            shifted = values - np.max(values)
            probabilities_array = np.exp(shifted) / np.sum(np.exp(shifted))
            probabilities = {
                class_name: float(probabilities_array[index])
                for index, class_name in enumerate(CLASSES)
            }
            predicted_index = int(np.argmax(probabilities_array))
            confidence = probabilities[CLASSES[predicted_index]]
        else:
            raise RuntimeError(
                f"Expected 1 binary output or {len(CLASSES)} class outputs ({CLASSES}), but the model returned shape {tuple(values.shape)}."
            )

        return {
            "prediction": CLASSES[predicted_index],
            "confidence": float(confidence),
            "probabilities": probabilities,
        }
