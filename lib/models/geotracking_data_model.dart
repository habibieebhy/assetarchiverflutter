class GeoTrackingPoint {
  // Required fields based on server schema/logic
  final int userId;
  final String journeyId;
  final double latitude;
  final double longitude;
  final bool isActive;

  // Location/Motion details
  final double? accuracy;
  final double? speed;
  final double? heading;
  final double? altitude;
  final String? recordedAt; // Server defaults to now(), but can be overridden

  // Trip details
  final double? destLat;
  final double? destLng;
  final double? totalDistanceTravelled;

  // App/Device state (Matching server schema)
  final String? locationType;
  final String? appState;
  final double? batteryLevel;
  final bool? isCharging;
  final String? networkStatus;
  final String? ipAddress;
  final String? siteName;
  final String? activityType;
  
  // Note: checkInTime/checkOutTime are handled server-side or via separate logic

  GeoTrackingPoint({
    required this.userId,
    required this.journeyId,
    required this.latitude,
    required this.longitude,
    this.isActive = true, // Matches server default
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
    this.recordedAt,
    this.destLat,
    this.destLng,
    this.totalDistanceTravelled,
    this.locationType,
    this.appState,
    this.batteryLevel,
    this.isCharging,
    this.networkStatus,
    this.ipAddress,
    this.siteName,
    this.activityType,
  });

  /// Converts the Dart object to a JSON map suitable for the server.
  /// Numeric values are converted to strings to preserve precision and match server expectations.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'journeyId': journeyId,
      'isActive': isActive,

      // Core Location/Trip fields (sent as strings to match server numeric handling)
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'destLat': destLat?.toString(),
      'destLng': destLng?.toString(),
      'accuracy': accuracy?.toStringAsFixed(2),
      'speed': speed?.toStringAsFixed(2),
      'heading': heading?.toStringAsFixed(2),
      'altitude': altitude?.toStringAsFixed(2),
      'totalDistanceTravelled': totalDistanceTravelled?.toStringAsFixed(3),
      
      // Optional state fields
      'recordedAt': recordedAt,
      'locationType': locationType,
      'appState': appState,
      'batteryLevel': batteryLevel?.toStringAsFixed(2),
      'isCharging': isCharging,
      'networkStatus': networkStatus,
      'ipAddress': ipAddress,
      'siteName': siteName,
      'activityType': activityType,
    };
  }
}

