import base64
from typing import Optional

import cloudinary
import cloudinary.uploader

from config import settings


def is_cloudinary_configured() -> bool:
    return bool(
        settings.cloudinary_cloud_name
        and settings.cloudinary_api_key
        and settings.cloudinary_api_secret
    )


def upload_image(
    contents: bytes,
    *,
    filename: str,
    content_type: str,
) -> Optional[str]:
    if not is_cloudinary_configured():
        return None

    cloudinary.config(
        cloud_name=settings.cloudinary_cloud_name,
        api_key=settings.cloudinary_api_key,
        api_secret=settings.cloudinary_api_secret,
        secure=True,
    )

    data = base64.b64encode(contents).decode("ascii")
    upload_source = f"data:{content_type};base64,{data}"
    public_id = filename.rsplit(".", 1)[0]

    result = cloudinary.uploader.upload(
        upload_source,
        folder=settings.cloudinary_folder,
        public_id=public_id,
        overwrite=False,
        resource_type="image",
    )

    secure_url = result.get("secure_url")
    return secure_url if isinstance(secure_url, str) else None
