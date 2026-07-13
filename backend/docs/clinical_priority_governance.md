# Clinical Priority Draft Boundary

`clinical-priority-v1-draft` is a deterministic implementation fixture, not a clinically approved ruleset. It uses explicit `true`, `false`, and `unknown` values for signs, symptoms, risk factors, and emergency flags. Missing or unknown required fields produce stable `missing.<field>` codes, except that any confirmed emergency flag overrides incompleteness.

The feature defaults to `disabled`. Academic or enabled deployment requires accountable review of intended use, input catalog, emergency flags, weights, thresholds, combinations, reason text, limitations, validation protocol, monitoring, and rollback criteria. Changes require a new immutable version. Outputs support attention timing only and must never be described as diagnosis, malignancy determination, cancer probability, or a replacement for professional judgment or emergency services.
