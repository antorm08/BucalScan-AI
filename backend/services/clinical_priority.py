import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from schemas import ClinicalAssessmentInput

_RULESET_PATH = Path(__file__).resolve().parent.parent / "rulesets" / "clinical_priority_v1_draft.json"
RULESET = json.loads(_RULESET_PATH.read_text(encoding="ascii"))
RULESET_ID = RULESET["ruleset_id"]
RULESET_VERSION = RULESET["version"]
ASSESSMENT_SCHEMA_VERSION = RULESET["assessment_schema_version"]
ENGINE_VERSION = RULESET["engine_version"]
EMERGENCY_FIELDS = tuple(RULESET["emergency_fields"])
WEIGHTS = RULESET["weights"]
PROMPT_THRESHOLD = RULESET["thresholds"]["prompt"]
URGENT_THRESHOLD = RULESET["thresholds"]["urgent"]
REASON_TEXT = RULESET["reason_text"]


@dataclass(frozen=True)
class PriorityEvaluation:
    priority_code: str
    reason_codes: tuple[str, ...]
    rendered_reasons: tuple[str, ...]
    completion_status: str
    score: int


def canonicalize(assessment: ClinicalAssessmentInput) -> dict[str, str]:
    # Pydantic rejects extra fields and unsupported values before this boundary.
    return {name: getattr(assessment, name) or "unknown" for name in assessment.model_fields}


def evaluate_priority(canonical: dict[str, str]) -> PriorityEvaluation:
    emergencies = [field for field in EMERGENCY_FIELDS if canonical[field] == "true"]
    if emergencies:
        codes = tuple(f"emergency.{field}" for field in emergencies)
        return PriorityEvaluation(
            "emergency",
            codes,
            tuple(f"Confirmed emergency flag: {field.replace('_', ' ')}." for field in emergencies),
            "incomplete" if any(value == "unknown" for value in canonical.values()) else "complete",
            0,
        )

    missing = [name for name, value in canonical.items() if value == "unknown"]
    if missing:
        codes = tuple(f"missing.{field}" for field in missing)
        return PriorityEvaluation(
            "incomplete",
            codes,
            tuple(f"Required field not assessed: {field.replace('_', ' ')}." for field in missing),
            "incomplete",
            0,
        )

    score = sum(weight for field, weight in WEIGHTS.items() if canonical[field] == "true")
    urgent_combination = any(
        all(canonical[field] == "true" for field in combination)
        for combination in RULESET["combinations"]["urgent"]
    )
    prompt_combination = canonical["persistence_over_two_weeks"] == "true" and any(
        canonical[field] == "true"
        for field in RULESET["combinations"]["prompt_persistence_signs"]
    )
    if score >= URGENT_THRESHOLD or urgent_combination:
        codes = []
        if score >= URGENT_THRESHOLD:
            codes.append("priority.urgent.score")
        if urgent_combination:
            codes.append("priority.urgent.high_concern_combination")
        priority_code = "urgent"
    elif score >= PROMPT_THRESHOLD or prompt_combination:
        codes = []
        if score >= PROMPT_THRESHOLD:
            codes.append("priority.prompt.score")
        if prompt_combination:
            codes.append("priority.prompt.persistence_sign")
        priority_code = "prompt"
    else:
        codes = ["priority.standard.complete"]
        priority_code = "standard"
    return PriorityEvaluation(
        priority_code,
        tuple(codes),
        tuple(REASON_TEXT[code] for code in codes),
        "complete",
        score,
    )


def result_dict(result: Any, completion_status: str | None = None) -> dict[str, Any]:
    return {
        "id": result.id,
        "assessment_id": result.assessment_id,
        "priority_code": result.priority_code,
        "reason_codes": list(result.reason_codes),
        "rendered_reasons": list(result.rendered_reasons),
        "ruleset_id": result.ruleset_id,
        "ruleset_version": result.ruleset_version,
        "engine_version": result.engine_version,
        "evaluated_at": result.evaluated_at,
        "completion_status": completion_status or result.assessment.completion_status,
    }
