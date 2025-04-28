class CategorySummary {
  final String category;
  final int total;

  CategorySummary({required this.category, required this.total});

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      category: json['category'],
      total: json['total'],
    );
  }
}
