"""Add CAM activations and classifier weights as outputs of the approved ONNX graph."""

from pathlib import Path

import onnx
from onnx import TensorProto, helper


BASE_DIR = Path(__file__).resolve().parent.parent
SOURCE_MODEL = BASE_DIR / "models" / "resnet50_oral.onnx"
OUTPUT_MODEL = BASE_DIR / "models" / "resnet50_oral_cam.onnx"


def _shape(value) -> list[int | str]:
    return [
        dimension.dim_value if dimension.HasField("dim_value") else dimension.dim_param
        for dimension in value.type.tensor_type.shape.dim
    ]


def main() -> None:
    model = onnx.load(SOURCE_MODEL, load_external_data=False)
    inferred = onnx.shape_inference.infer_shapes(model)
    shapes = {
        value.name: _shape(value)
        for value in inferred.graph.value_info
    }

    activation_candidates = [
        node.input[0]
        for node in model.graph.node
        if node.op_type == "ReduceMean"
        and shapes.get(node.input[0], [])[1:] == [2048, 7, 7]
    ]
    classifier_nodes = [node for node in model.graph.node if node.op_type == "Gemm"]
    if len(activation_candidates) != 1 or len(classifier_nodes) != 1:
        raise RuntimeError("Expected one final ResNet activation and one classifier node.")

    activation_name = activation_candidates[0]
    classifier_weight_name = classifier_nodes[0].input[1]
    model.graph.node.extend([
        helper.make_node("Identity", [activation_name], ["cam_activations"], name="cam_activations_output"),
        helper.make_node("Identity", [classifier_weight_name], ["cam_weights"], name="cam_weights_output"),
    ])
    model.graph.output.extend([
        helper.make_tensor_value_info("cam_activations", TensorProto.FLOAT, ["batch_size", 2048, 7, 7]),
        helper.make_tensor_value_info("cam_weights", TensorProto.FLOAT, [1, 2048]),
    ])
    onnx.save(model, OUTPUT_MODEL)
    onnx.checker.check_model(OUTPUT_MODEL)
    print(f"CAM model written to {OUTPUT_MODEL}")


if __name__ == "__main__":
    main()
