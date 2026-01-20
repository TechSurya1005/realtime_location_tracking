class Report {
  final String id;
  final String title;
  final String description;
  final List<String> imagePaths;
  final DateTime submittedAt;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePaths,
    required this.submittedAt,
  });
}
