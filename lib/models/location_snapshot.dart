class LocationSnapshot {
  const LocationSnapshot({
    required this.companyAddress,
    required this.currentAddress,
    required this.distanceKm,
    required this.isWithinAllowedRadius,
    required this.accuracy,
    required this.latitude,
    required this.longitude,
    required this.companyLatitude,
    required this.companyLongitude,
  });

  final String companyAddress;
  final String currentAddress;
  final double distanceKm;
  final bool isWithinAllowedRadius;
  final double accuracy;
  final double latitude;
  final double longitude;
  final double companyLatitude;
  final double companyLongitude;
}
