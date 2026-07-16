import io
from html import escape
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener

from PIL import Image as PillowImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Image, KeepTogether, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


_UPLOADS_DIR = Path(__file__).resolve().parent.parent / "uploads"
_MAX_ASSET_BYTES = 8 * 1024 * 1024
_ALLOWED_REMOTE_HOSTS = {"res.cloudinary.com"}


class _NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def _asset_bytes(stored_value: str | None) -> bytes | None:
    if not stored_value:
        return None
    try:
        if stored_value.startswith("https://"):
            if urlparse(stored_value).hostname not in _ALLOWED_REMOTE_HOSTS:
                return None
            request = Request(stored_value, headers={"User-Agent": "BucalScan-AI/1.0"})
            with build_opener(_NoRedirect).open(request, timeout=5) as response:
                content_length = response.headers.get("Content-Length")
                if content_length and int(content_length) > _MAX_ASSET_BYTES:
                    return None
                data = response.read(_MAX_ASSET_BYTES + 1)
        elif stored_value.startswith("http://"):
            return None
        else:
            data = (_UPLOADS_DIR / Path(stored_value).name).read_bytes()
        if len(data) > _MAX_ASSET_BYTES:
            return None
        return data
    except (OSError, ValueError):
        return None


def _report_image(stored_value: str | None, width: float = 7.5 * cm) -> Image | None:
    data = _asset_bytes(stored_value)
    if data is None:
        return None
    try:
        with PillowImage.open(io.BytesIO(data)) as source:
            source = source.convert("RGB")
            source.thumbnail((1200, 1200))
            encoded = io.BytesIO()
            source.save(encoded, format="JPEG", quality=85, optimize=True)
            image_width, image_height = source.size
        encoded.seek(0)
        height = width * image_height / image_width
        return Image(encoded, width=width, height=height)
    except (OSError, ValueError, ZeroDivisionError):
        return None


def _text(value: object | None, fallback: str = "No registrado") -> str:
    normalized = str(value).strip() if value is not None else ""
    return escape(normalized or fallback)


def _date(value) -> str:
    return value.strftime("%d/%m/%Y %H:%M")


def build_evaluation_pdf(*, patient, lesion, evaluation, professional) -> bytes:
    buffer = io.BytesIO()
    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=1.7 * cm,
        leftMargin=1.7 * cm,
        topMargin=1.5 * cm,
        bottomMargin=1.5 * cm,
        title=f"BucalScan AI - Evaluacion {evaluation.id}",
        author="BucalScan AI",
        pageCompression=0,
    )
    styles = getSampleStyleSheet()
    styles.add(
        ParagraphStyle(
            name="ReportTitle",
            parent=styles["Title"],
            fontName="Helvetica-Bold",
            fontSize=20,
            textColor=colors.HexColor("#123A40"),
            alignment=TA_CENTER,
            spaceAfter=12,
        )
    )
    styles.add(
        ParagraphStyle(
            name="Section",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12,
            textColor=colors.HexColor("#123A40"),
            spaceBefore=10,
            spaceAfter=6,
        )
    )
    styles.add(
        ParagraphStyle(
            name="Disclaimer",
            parent=styles["BodyText"],
            fontSize=9,
            leading=12,
            textColor=colors.HexColor("#5C6264"),
            borderColor=colors.HexColor("#C8D4D6"),
            borderWidth=1,
            borderPadding=8,
            backColor=colors.HexColor("#F1F6F6"),
        )
    )

    story = [
        Paragraph("BucalScan AI", styles["ReportTitle"]),
        Paragraph("Informe orientativo de evaluacion", styles["Heading1"]),
        Table(
            [
                ["Codigo clinico", Paragraph(_text(patient.clinical_code), styles["BodyText"])],
                ["Localizacion de la lesion", Paragraph(_text(lesion.anatomical_site), styles["BodyText"])],
                ["Fecha de evaluacion", Paragraph(_date(evaluation.evaluated_at), styles["BodyText"])],
                ["Profesional", Paragraph(_text(professional.full_name), styles["BodyText"])],
                ["Registro profesional", Paragraph(_text(professional.doctor_id), styles["BodyText"])],
            ],
            colWidths=[5.2 * cm, 11 * cm],
            style=TableStyle(
                [
                    ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#E6F0F1")),
                    ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#C8D4D6")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("PADDING", (0, 0), (-1, -1), 6),
                ]
            ),
        ),
        Paragraph("Hallazgos registrados", styles["Section"]),
        Paragraph(_text(evaluation.clinical_observations), styles["BodyText"]),
    ]

    source_image = _report_image(evaluation.image.storage_url if evaluation.image else None)
    story.extend([Paragraph("Imagen evaluada", styles["Section"])])
    story.append(source_image or Paragraph("Imagen no disponible.", styles["BodyText"]))

    prediction = evaluation.prediction
    story.append(Paragraph("Resultado tecnico del modelo", styles["Section"]))
    if prediction is None:
        story.append(Paragraph("Resultado del modelo no disponible.", styles["BodyText"]))
    else:
        story.append(
            Table(
                [
                    ["Salida del clasificador", Paragraph(_text(prediction.predicted_label), styles["BodyText"])],
                    ["Confianza tecnica", Paragraph(f"{prediction.confidence * 100:.1f} %", styles["BodyText"])],
                    ["Salida maligna", Paragraph(f"{prediction.malignant_probability * 100:.1f} %", styles["BodyText"])],
                    ["Version del modelo", Paragraph(_text(prediction.model_version), styles["BodyText"])],
                ],
                colWidths=[5.2 * cm, 11 * cm],
                style=TableStyle(
                    [
                        ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#E6F0F1")),
                        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#C8D4D6")),
                        ("PADDING", (0, 0), (-1, -1), 6),
                    ]
                ),
            )
        )
        cam = _report_image(prediction.heatmap_url)
        story.append(Paragraph("Mapa CAM", styles["Section"]))
        story.append(
            KeepTogether(
                [
                    cam or Paragraph("Mapa CAM no disponible.", styles["BodyText"]),
                    Spacer(1, 4),
                    Paragraph(
                        "Visualizacion explicativa de las regiones que influyeron en la salida del modelo; no localiza por si sola una lesion ni constituye diagnostico.",
                        styles["BodyText"],
                    ),
                ]
            )
        )

    priority = (
        evaluation.assessment_snapshot.priority_result
        if evaluation.assessment_snapshot and evaluation.assessment_snapshot.priority_result
        else None
    )
    story.append(Paragraph("Orientacion academica registrada", styles["Section"]))
    if priority is None:
        story.append(Paragraph("No se registro orientacion academica para esta evaluacion.", styles["BodyText"]))
    else:
        reasons = priority.rendered_reasons or ["Sin motivos registrados."]
        story.extend(
            [
                Paragraph(f"Codigo: <b>{_text(priority.priority_code)}</b>", styles["BodyText"]),
                *[Paragraph(f"- {_text(reason)}", styles["BodyText"]) for reason in reasons],
                Paragraph(
                    f"Reglas: {_text(priority.ruleset_id)} / {_text(priority.ruleset_version)}",
                    styles["BodyText"],
                ),
            ]
        )

    story.extend(
        [
            Spacer(1, 14),
            Paragraph(
                "Este informe presenta una salida tecnica orientativa. No constituye diagnostico, no representa probabilidad clinica de cancer y no sustituye la evaluacion de un profesional de salud.",
                styles["Disclaimer"],
            ),
        ]
    )
    document.build(story)
    return buffer.getvalue()
