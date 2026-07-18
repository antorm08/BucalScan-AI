from dataclasses import dataclass

import cv2
import numpy as np
from PIL import Image

from config import settings


@dataclass(frozen=True)
class ImageQualityResult:
    is_valid: bool
    reasons: tuple[str, ...]
    width: int
    height: int
    blur_score: float
    dark_ratio: float
    bright_ratio: float


def validate_image_quality(image: Image.Image) -> ImageQualityResult:
    rgb_image = np.asarray(image.convert("RGB"), dtype=np.uint8)
    height, width = rgb_image.shape[:2]

    gray_image = cv2.cvtColor(rgb_image, cv2.COLOR_RGB2GRAY)
    # Oral images contain large, naturally smooth mucosal regions. Measure a
    # robust set of local regions instead of penalizing the whole photograph.
    tile_rows = np.array_split(gray_image, 4, axis=0)
    tile_scores = [
        float(cv2.Laplacian(tile, cv2.CV_64F).var())
        for row in tile_rows
        for tile in np.array_split(row, 4, axis=1)
    ]
    blur_score = float(np.percentile(tile_scores, 75))

    luminance = cv2.cvtColor(rgb_image, cv2.COLOR_RGB2YUV)[:, :, 0]
    dark_ratio = float(np.mean(luminance <= settings.image_dark_luminance))
    bright_ratio = float(np.mean(luminance >= settings.image_bright_luminance))

    reasons = []
    if width < settings.image_min_width or height < settings.image_min_height:
        reasons.append("low_resolution")
    if blur_score < settings.image_blur_threshold:
        reasons.append("blurry")
    if dark_ratio > settings.image_max_dark_ratio:
        reasons.append("too_dark")
    if bright_ratio > settings.image_max_bright_ratio:
        reasons.append("overexposed")

    return ImageQualityResult(
        is_valid=not reasons,
        reasons=tuple(reasons),
        width=width,
        height=height,
        blur_score=blur_score,
        dark_ratio=dark_ratio,
        bright_ratio=bright_ratio,
    )
