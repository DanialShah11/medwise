class ExportMetadata {
  final String fileName;
  final String format;
  final DateTime timestamp;
  final Map<String, dynamic> filters;

  ExportMetadata({
    required this.fileName,
    required this.format,
    required this.timestamp,
    required this.filters,
  });

  Map<String, dynamic> toJson() => {
    "fileName": fileName,
    "format": format,
    "timestamp": timestamp.toIso8601String(),
    "filters": filters,
  };

  static ExportMetadata fromJson(Map<String, dynamic> json) => ExportMetadata(
    fileName: json["fileName"],
    format: json["format"],
    timestamp: DateTime.parse(json["timestamp"]),
    filters: Map<String, dynamic>.from(json["filters"] ?? {}),
  );

  Map<String, dynamic> toMap() => toJson(); // for Firestore
}
