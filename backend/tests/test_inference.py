"""
Automated tests for OralLesionClassifier.
Run from backend/ directory: pytest tests/test_inference.py -v
"""
import hashlib
import io
import sys
from pathlib import Path

import numpy as np
import pytest
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from models.inference import CLASSES, OralLesionClassifier

MODEL_PATH = Path(__file__).resolve().parent.parent / "models" / "resnet50_oral.onnx"
MODEL_DATA_PATH = MODEL_PATH.with_suffix(".onnx.data")
CAM_MODEL_PATH = MODEL_PATH.with_name("resnet50_oral_cam.onnx")
APPROVED_SHA256 = {
    MODEL_PATH.name: "f306e10a5a603788e55af425439bef67817ed926872e8a95f418aa7fd9d444dc",
    MODEL_DATA_PATH.name: "2efdd0ccb3f0541a0c0b692276c5807f4342a67af7cadb94c2a58fecba59d25a",
}
CAM_GRAPH_SHA256 = "9f1e9353b2d334adf5781f5c1b276ea9f61a167a4ccbdf1fb8e42bd39b020ab5"
TEST_IMAGE_PATH = Path(__file__).resolve().parent.parent / "test_images" / "ejemplo.png"


@pytest.fixture(scope="module")
def classifier():
    if not MODEL_PATH.exists():
        pytest.skip(f"Model not found at {MODEL_PATH}")
    return OralLesionClassifier(str(MODEL_PATH))


@pytest.fixture(scope="module")
def cam_classifier():
    return OralLesionClassifier(str(CAM_MODEL_PATH))


def _make_dummy_image(width: int = 224, height: int = 224) -> Image.Image:
    array = np.random.randint(0, 256, (height, width, 3), dtype=np.uint8)
    return Image.fromarray(array, mode="RGB")


class TestModelLoading:
    @pytest.mark.parametrize("path", [MODEL_PATH, MODEL_DATA_PATH])
    def test_approved_resnet50_checksum(self, path):
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        assert digest == APPROVED_SHA256[path.name]

    def test_model_loads(self, classifier):
        assert classifier.model is not None

    def test_input_name_is_set(self, classifier):
        assert classifier.input_name is not None
        assert isinstance(classifier.input_name, str)

    def test_model_path_exists(self, classifier):
        assert classifier.model_path.exists()

    def test_model_contract(self, classifier):
        classifier.validate_contract()

    def test_cam_graph_checksum_and_contract(self, cam_classifier):
        digest = hashlib.sha256(CAM_MODEL_PATH.read_bytes()).hexdigest()
        assert digest == CAM_GRAPH_SHA256
        cam_classifier.validate_contract()


class TestPreprocess:
    def test_output_shape(self, classifier):
        img = _make_dummy_image()
        tensor = classifier._preprocess(img)
        assert tensor.shape == (1, 3, 224, 224)

    def test_output_dtype(self, classifier):
        img = _make_dummy_image()
        tensor = classifier._preprocess(img)
        assert tensor.dtype == np.float32

    def test_rgb_conversion(self, classifier):
        rgba_img = Image.new("RGBA", (100, 100), (255, 0, 0, 128))
        tensor = classifier._preprocess(rgba_img)
        assert tensor.shape == (1, 3, 224, 224)

    def test_small_image_resized(self, classifier):
        small = _make_dummy_image(50, 50)
        tensor = classifier._preprocess(small)
        assert tensor.shape == (1, 3, 224, 224)

    def test_large_image_resized(self, classifier):
        large = _make_dummy_image(1024, 1024)
        tensor = classifier._preprocess(large)
        assert tensor.shape == (1, 3, 224, 224)


class TestPredict:
    def test_returns_required_keys(self, classifier):
        result = classifier.predict(_make_dummy_image())
        assert "prediction" in result
        assert "confidence" in result
        assert "probabilities" in result

    def test_prediction_is_valid_class(self, classifier):
        result = classifier.predict(_make_dummy_image())
        assert result["prediction"] in CLASSES

    def test_confidence_in_range(self, classifier):
        result = classifier.predict(_make_dummy_image())
        assert 0.0 <= result["confidence"] <= 1.0

    def test_probabilities_sum_to_one(self, classifier):
        result = classifier.predict(_make_dummy_image())
        total = sum(result["probabilities"].values())
        assert abs(total - 1.0) < 1e-5

    def test_probabilities_cover_all_classes(self, classifier):
        result = classifier.predict(_make_dummy_image())
        assert set(result["probabilities"].keys()) == set(CLASSES)

    def test_confidence_matches_prediction(self, classifier):
        result = classifier.predict(_make_dummy_image())
        assert result["confidence"] == pytest.approx(
            result["probabilities"][result["prediction"]], abs=1e-6
        )

    def test_with_real_test_image(self, classifier):
        if not TEST_IMAGE_PATH.exists():
            pytest.skip(f"Test image not found at {TEST_IMAGE_PATH}")
        img = Image.open(TEST_IMAGE_PATH)
        result = classifier.predict(img)
        assert result["prediction"] in CLASSES
        assert 0.0 <= result["confidence"] <= 1.0

    def test_raises_without_model(self):
        clf = OralLesionClassifier.__new__(OralLesionClassifier)
        clf.model = None
        clf.input_name = None
        clf.model_path = Path("nonexistent.onnx")
        with pytest.raises(RuntimeError, match="Model file not loaded"):
            clf.predict(_make_dummy_image())

    def test_cam_keeps_prediction_and_returns_aligned_rgba_png(
        self, classifier, cam_classifier
    ):
        image = _make_dummy_image(width=320, height=240)

        expected = classifier.predict(image)
        result = cam_classifier.predict_with_heatmap(image)
        heatmap = Image.open(io.BytesIO(result["heatmap_png"]))

        assert result["prediction"] == expected["prediction"]
        assert result["probabilities"] == pytest.approx(
            expected["probabilities"], abs=1e-6
        )
        assert heatmap.mode == "RGBA"
        assert heatmap.size == image.size
