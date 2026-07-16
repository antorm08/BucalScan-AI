-- Read-only post-migration checks. Every orphan count and invalid count must be zero.
SELECT (SELECT COUNT(*) FROM users) AS users,
       (SELECT COUNT(*) FROM workspace_memberships) AS memberships,
       (SELECT COUNT(*) FROM analyses) AS analyses,
       (SELECT COUNT(*) FROM clinical_evaluations) AS evaluations,
       (SELECT COUNT(*) FROM model_predictions) AS predictions;
SELECT COUNT(*) AS analyses_without_evaluation FROM analyses WHERE evaluation_id IS NULL;
SELECT COUNT(*) AS orphan_memberships FROM workspace_memberships m
LEFT JOIN users u ON u.id=m.user_id LEFT JOIN clinical_workspaces w ON w.id=m.workspace_id
WHERE u.id IS NULL OR w.id IS NULL;
SELECT COUNT(*) AS orphan_evaluations FROM clinical_evaluations e
LEFT JOIN patients p ON p.id=e.patient_id LEFT JOIN oral_lesions l ON l.id=e.lesion_id
WHERE p.id IS NULL OR l.id IS NULL OR p.workspace_id<>e.workspace_id OR l.workspace_id<>e.workspace_id;
SELECT COUNT(*) AS invalid_predictions FROM model_predictions
WHERE confidence<0 OR confidence>1 OR benign_probability<0 OR benign_probability>1
   OR malignant_probability<0 OR malignant_probability>1
   OR abs((benign_probability+malignant_probability)-1)>0.00001
   OR model_version IS NULL OR created_at IS NULL;
SELECT COUNT(*) AS missing_image_references FROM lesion_images WHERE storage_url IS NULL OR storage_url='';
SELECT COUNT(*) AS invalid_heatmap_references FROM model_predictions
WHERE heatmap_url IS NOT NULL AND btrim(heatmap_url)='';
SELECT COUNT(*) AS heatmap_column_count FROM information_schema.columns
WHERE table_schema=current_schema() AND table_name='model_predictions' AND column_name='heatmap_url';
SELECT a.id, a.prediction, a.confidence, a.timestamp, a.model_version,
       p.predicted_label, p.confidence AS normalized_confidence, p.created_at
FROM analyses a JOIN clinical_evaluations e ON e.id=a.evaluation_id
JOIN model_predictions p ON p.evaluation_id=e.id
WHERE a.prediction<>p.predicted_label OR abs(a.confidence-p.confidence)>0.00001;
