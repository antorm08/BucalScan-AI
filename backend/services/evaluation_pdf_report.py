import io
from html import escape
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener

from PIL import Image as PillowImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
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


def _report_image(
    stored_value: str | None,
    width: float = 7.5 * cm,
    max_height: float = 7 * cm,
) -> Image | None:
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
        scale = min(width / image_width, max_height / image_height)
        return Image(encoded, width=image_width * scale, height=image_height * scale)
    except (OSError, ValueError, ZeroDivisionError):
        return None


def _text(value: object | None, fallback: str = "No registrado") -> str:
    normalized = str(value).strip() if value is not None else ""
    return escape(normalized or fallback)


def _date(value) -> str:
    return value.strftime("%d/%m/%Y %H:%M")


def _date_only(value) -> str:
    return value.strftime("%d/%m/%Y") if value else "No registrada"


def _page_chrome(canvas, document) -> None:
    canvas.saveState()
    width, height = A4
    canvas.setStrokeColor(colors.HexColor("#D6DEE6"))
    canvas.setLineWidth(0.5)
    canvas.line(document.leftMargin, height - 1.05 * cm, width - document.rightMargin, height - 1.05 * cm)
    canvas.setFont("Helvetica-Bold", 8)
    canvas.setFillColor(colors.HexColor("#00355F"))
    canvas.drawString(document.leftMargin, height - 0.78 * cm, "BucalScan AI")
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#5D6670"))
    canvas.drawRightString(
        width - document.rightMargin,
        height - 0.78 * cm,
        "Informe de apoyo técnico · No diagnóstico",
    )
    canvas.line(document.leftMargin, 1.05 * cm, width - document.rightMargin, 1.05 * cm)
    canvas.drawString(document.leftMargin, 0.68 * cm, "Documento clínico confidencial")
    canvas.drawRightString(width - document.rightMargin, 0.68 * cm, f"Página {canvas.getPageNumber()}")
    canvas.restoreState()


def build_evaluation_pdf(*, patient, lesion, evaluation, professional) -> bytes:
    buffer = io.BytesIO()
    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=1.7 * cm,
        leftMargin=1.7 * cm,
        topMargin=1.45 * cm,
        bottomMargin=1.35 * cm,
        title=f"BucalScan AI - Evaluación {evaluation.id}",
        author="BucalScan AI",
        pageCompression=0,
    )
    styles = getSampleStyleSheet()
    styles.add(
        ParagraphStyle(
            name="ReportTitle",
            parent=styles["Title"],
            fontName="Helvetica-Bold",
            fontSize=22,
            leading=26,
            textColor=colors.white,
            alignment=TA_LEFT,
            spaceAfter=0,
        )
    )
    styles.add(
        ParagraphStyle(
            name="Section",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=13,
            leading=16,
            textColor=colors.HexColor("#00355F"),
            spaceBefore=14,
            spaceAfter=8,
        )
    )
    styles.add(
        ParagraphStyle(
            name="Disclaimer",
            parent=styles["BodyText"],
            fontSize=9.2,
            leading=13,
            textColor=colors.HexColor("#42474F"),
            borderColor=colors.HexColor("#AFC7DD"),
            borderWidth=1,
            borderPadding=10,
            backColor=colors.HexColor("#EDF5FF"),
        )
    )
    styles.add(
        ParagraphStyle(
            name="Label",
            parent=styles["BodyText"],
            fontName="Helvetica-Bold",
            fontSize=8,
            leading=10,
            textColor=colors.HexColor("#5D6670"),
            spaceAfter=2,
        )
    )
    styles.add(
        ParagraphStyle(
            name="Value",
            parent=styles["BodyText"],
            fontSize=10,
            leading=14,
            textColor=colors.HexColor("#191C1E"),
        )
    )
    styles.add(
        ParagraphStyle(
            name="Caption",
            parent=styles["BodyText"],
            fontSize=8.5,
            leading=11,
            textColor=colors.HexColor("#5D6670"),
            alignment=TA_CENTER,
        )
    )

    def field(label, value):
        return [Paragraph(label.upper(), styles["Label"]), Paragraph(_text(value), styles["Value"])]

    def details_table(rows):
        return Table(
            rows,
            colWidths=[8.1 * cm, 8.1 * cm],
            style=TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F7F9FB")),
                    ("BOX", (0, 0), (-1, -1), 0.7, colors.HexColor("#C2C7D1")),
                    ("INNERGRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E0E3E5")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 9),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 9),
                    ("TOPPADDING", (0, 0), (-1, -1), 8),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                ]
            ),
        )

    story = [
        Table(
            [[
                Paragraph("BucalScan AI", styles["ReportTitle"]),
                Paragraph(
                    f"<b>INFORME DE EVALUACIÓN</b><br/><font size='9'>ID {_text(evaluation.id)} · {_date(evaluation.evaluated_at)}</font>",
                    ParagraphStyle(
                        "HeroMeta",
                        parent=styles["BodyText"],
                        textColor=colors.white,
                        alignment=TA_LEFT,
                        leading=14,
                    ),
                ),
            ]],
            colWidths=[7.1 * cm, 9.1 * cm],
            style=TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#00355F")),
                    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 14),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 14),
                    ("TOPPADDING", (0, 0), (-1, -1), 14),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 14),
                ]
            ),
        ),
        Spacer(1, 12),
        Paragraph(
            "Documento de apoyo técnico para seguimiento profesional. No constituye diagnóstico ni indica por sí solo una conducta clínica.",
            styles["Disclaimer"],
        ),
        Paragraph("Resumen clínico", styles["Section"]),
        details_table(
            [
                [field("Código clínico", patient.clinical_code), field("Sitio anatómico", lesion.anatomical_site)],
                [field("Estado de la lesión", lesion.status), field("Primera observación", _date_only(lesion.observed_at))],
                [field("Duración estimada", lesion.estimated_duration), field("Fecha de evaluación", _date(evaluation.evaluated_at))],
                [field("Profesional", professional.full_name), field("Registro", professional.doctor_id)],
                [field("Profesión", professional.profession), field("Especialidad", professional.specialty)],
            ]
        ),
        Paragraph("Registro profesional", styles["Section"]),
        Table(
            [[
                Paragraph("<b>Hallazgos de esta evaluación</b><br/>" + _text(evaluation.clinical_observations), styles["Value"]),
                Paragraph("<b>Notas longitudinales de la lesión</b><br/>" + _text(lesion.clinical_notes), styles["Value"]),
            ]],
            colWidths=[8.1 * cm, 8.1 * cm],
            style=TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F2F4F6")),
                ("BOX", (0, 0), (-1, -1), 0.7, colors.HexColor("#C2C7D1")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("PADDING", (0, 0), (-1, -1), 10),
            ]),
        ),
    ]

    source_image = _report_image(evaluation.image.storage_url if evaluation.image else None, 10 * cm, 8 * cm)
    story.extend([
        Paragraph("Evidencia visual", styles["Section"]),
        source_image or Paragraph("Imagen no disponible.", styles["BodyText"]),
        Spacer(1, 5),
        Paragraph("Imagen clínica aportada para esta evaluación.", styles["Caption"]),
    ])

    prediction = evaluation.prediction
    story.append(Paragraph("Salida técnica del clasificador", styles["Section"]))
    if prediction is None:
        story.append(Paragraph("Resultado del modelo no disponible.", styles["BodyText"]))
    else:
        story.append(
            details_table(
                [
                    [field("Salida del clasificador", prediction.predicted_label), field("Confianza técnica", f"{prediction.confidence * 100:.1f} %")],
                    [field("Puntuación benigna", f"{prediction.benign_probability * 100:.1f} %"), field("Puntuación maligna", f"{prediction.malignant_probability * 100:.1f} %")],
                    [field("Versión del modelo", prediction.model_version), field("Tiempo de proceso", f"{prediction.processing_time_ms:.0f} ms" if prediction.processing_time_ms is not None else None)],
                ]
            )
        )
        story.extend([
            Spacer(1, 7),
            Paragraph(
                "Las puntuaciones y la confianza son salidas internas del clasificador; no representan una probabilidad clínica de cáncer.",
                styles["Disclaimer"],
            ),
        ])
        cam = _report_image(prediction.heatmap_url)
        story.append(Paragraph("Mapa de activación CAM", styles["Section"]))
        story.append(
            KeepTogether(
                [
                    cam or Paragraph("Mapa CAM no disponible.", styles["BodyText"]),
                    Spacer(1, 4),
                    Paragraph(
                        "Representa regiones que influyeron en la salida del modelo. No delimita por sí solo una lesión, no explica causalidad y no constituye diagnóstico.",
                        styles["Caption"],
                    ),
                ]
            )
        )

    priority = (
        evaluation.assessment_snapshot.priority_result
        if evaluation.assessment_snapshot and evaluation.assessment_snapshot.priority_result
        else None
    )
    snapshot = evaluation.assessment_snapshot
    story.append(Paragraph("Prioridad clínica orientativa", styles["Section"]))
    if priority is None:
        story.append(Paragraph("No se registró prioridad clínica para esta evaluación.", styles["BodyText"]))
    else:
        reasons = priority.rendered_reasons or ["Sin motivos registrados."]
        priority_labels = {
            "incomplete": "Evaluación incompleta",
            "standard": "Atención estándar",
            "prompt": "Atención pronta",
            "urgent": "Atención urgente",
            "emergency": "Atención de emergencia",
        }
        story.extend(
            [
                details_table([
                    [field("Orientación registrada", priority_labels.get(priority.priority_code, priority.priority_code)), field("Estado del cuestionario", snapshot.completion_status if snapshot else None)],
                    [field("Ruleset", priority.ruleset_id), field("Versión / motor", f"{priority.ruleset_version} / {priority.engine_version}")],
                ]),
                Spacer(1, 7),
                Paragraph("<b>Motivos registrados</b>", styles["Value"]),
                *[Paragraph(f"• {_text(reason)}", styles["Value"]) for reason in reasons],
                Spacer(1, 6),
                Paragraph(
                    "Orientación académica versionada y no diagnóstica; no reemplaza el juicio profesional ni los servicios de emergencia.",
                    styles["Disclaimer"],
                ),
            ]
        )

    consent = evaluation.consent_attestation
    if consent is not None:
        story.extend([
            Paragraph("Trazabilidad", styles["Section"]),
            details_table([
                [field("Evaluación", f"ID {evaluation.id}"), field("Autorización atestada", _date(consent.attested_at))],
                [field("Modelo", prediction.model_version if prediction else None), field("Ruleset", priority.ruleset_version if priority else None)],
            ]),
        ])

    story.extend(
        [
            Spacer(1, 14),
            Paragraph(
                "Limitaciones: este informe no diagnostica, no confirma ni descarta enfermedad, y no representa una probabilidad clínica calibrada de cáncer. La calidad de la imagen, el contexto disponible y las limitaciones del modelo pueden afectar sus salidas. La interpretación y conducta corresponden al profesional de salud.",
                styles["Disclaimer"],
            ),
        ]
    )
    document.build(story, onFirstPage=_page_chrome, onLaterPages=_page_chrome)
    return buffer.getvalue()
