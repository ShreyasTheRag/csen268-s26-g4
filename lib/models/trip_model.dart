class Trip {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> locations;
  final List<String> images;
  final String notes;

  Trip({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.locations = const [],
    this.images = const [],
    this.notes = '',
  });

  Trip copyWith({
    DateTime? start,
    DateTime? end,
    String? notes,
    List<String>? images,
  }) {
    return Trip(
      name: name,
      startDate: start ?? startDate,
      endDate: end ?? endDate,
      notes: notes ?? this.notes,
      locations: locations,
      images: images ?? this.images,
    );
  }
}