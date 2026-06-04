class TakePictureArgs {
  const TakePictureArgs({
    required this.tripId,
    this.forSupplies = false,
  });

  final String tripId;
  final bool forSupplies;
}
