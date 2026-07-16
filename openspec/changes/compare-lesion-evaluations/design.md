## Context

`GET /api/v1/lesions/{id}` already returns the complete chronological evaluation list for one authorized lesion. Each complete evaluation includes the original image, classifier label/confidence/probabilities, model version, findings, and timestamp. Flutter currently renders these records as independent timeline cards and has no comparison interaction.

## Goals / Non-Goals

**Goals:**
- Compare exactly two complete evaluations from the currently loaded lesion.
- Default to the two most recent comparable evaluations while allowing either side to be changed.
- Keep source images and immutable stored values authoritative; calculate display deltas only in Flutter.
- Distinguish classifier-output differences from clinical progression through explicit wording.
- Remain usable on narrow phones and large text without requiring horizontal page scrolling.

**Non-Goals:**
- New backend queries, migrations, image registration, segmentation, or progression scoring.
- Recalculating historical predictions or comparing evaluations from different lesions.
- Claiming that confidence or malignant-output changes represent cancer probability, diagnosis, or lesion evolution.

## Decisions

### Use lesion detail data without another request
The comparison view receives the already authorized lesion and its evaluation list. Eligible evaluations require both an image and model prediction. This guarantees same-lesion scope and avoids a duplicate API contract.

Alternative considered: add a comparison endpoint. Rejected because it would return the same immutable fields already loaded and create unnecessary server logic.

### Use two selectors and a responsive side-by-side body
The view initializes the older of the two latest evaluations on the left and the latest on the right. Selectors prevent choosing the same evaluation twice. Images and compact metrics use two equal columns; long findings and safety copy remain full width below so narrow layouts stay readable.

Alternative considered: unrestricted multi-select. Rejected because more than two images make mobile comparison unreadable and the requested operation is pairwise.

### Show both confidence and malignant-output delta with safe semantics
Each side displays its own predicted class and confidence. The summary calculates signed confidence difference and signed malignant-output difference from stored probabilities. Copy states that these are numerical classifier differences, may involve different predicted classes/model versions, and do not establish clinical progression.

Alternative considered: present a green/red improvement indicator. Rejected because higher or lower model output is not a validated progression measure.

## Risks / Trade-offs

- [Different model versions reduce comparability] -> Display both versions and warn when they differ.
- [Confidence values refer to different winning classes] -> Display labels beside confidence and keep the delta neutral rather than calling it improvement/deterioration.
- [Two columns become narrow] -> Keep each card compact, use fixed aspect-ratio images, wrap text, and place detailed findings below.
- [Incomplete historical evaluations] -> Exclude records missing image or prediction and explain why comparison is unavailable.
