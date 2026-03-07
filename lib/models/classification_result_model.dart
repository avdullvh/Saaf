// ─────────────────────────────────────────────
// lib/models/classification_result_model.dart
// Maps directly to { predicted_type, confidence_score }
// ─────────────────────────────────────────────
class ClassificationResult {
  final String predictedType;    // e.g. "Khalas", "Razeez", "Shishi"
  final double confidenceScore;  // 0.0 – 1.0

  const ClassificationResult({
    required this.predictedType,
    required this.confidenceScore,
  });

  factory ClassificationResult.fromJson(Map<String, dynamic> j) =>
      ClassificationResult(
        predictedType:   j['predicted_type']   as String,
        confidenceScore: (j['confidence_score'] as num).toDouble(),
      );

  // Human-readable percentage string e.g. "98.4%"
  String get confidencePercent =>
      '${(confidenceScore * 100).toStringAsFixed(1)}%';

  // ── Mock factory used while backend is not ready ──
  factory ClassificationResult.mock() => const ClassificationResult(
    predictedType:   'Khalas',
    confidenceScore: 0.9837,
  );
}
