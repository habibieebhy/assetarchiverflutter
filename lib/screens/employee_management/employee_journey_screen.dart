import 'dart:async';
import 'dart:convert';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/models/geotracking_data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:polyline_codec/polyline_codec.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeJourneyScreen extends StatefulWidget {
  final Employee employee;
  final Map<String, dynamic>? initialJourneyData;
  final VoidCallback? onDestinationConsumed;

  const EmployeeJourneyScreen({
    super.key,
    required this.employee,
    this.initialJourneyData,
    this.onDestinationConsumed,
  });

  @override
  State<EmployeeJourneyScreen> createState() => _EmployeeJourneyScreenState();
}

class _EmployeeJourneyScreenState extends State<EmployeeJourneyScreen> {
  final Completer<MapLibreMapController> _controllerCompleter = Completer();
  late Future<String> _styleFuture;
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final String? _stadiaApiKey = dotenv.env['STADIA_API_KEY'];
  final String? _radarApiKey = dotenv.env['RADAR_API_KEY'];

  final ApiService _apiService = ApiService();

  bool _isJourneyActive = false;
  double _totalDistanceTravelled = 0.0;
  Position? _lastRecordedPosition;
  String? _currentJourneyId;
  String? _currentPjpId;
  LatLng? _currentUserLocation;
  LatLng? _destinationLocation;

  final List<LatLng> _routeTaken = [];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isNearDestinationNotified = false;

  // --- MODIFIED: Replaced _distanceCalculationTimer with two new controllers ---
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _radarArrivalCheckTimer;
  // --- END MODIFICATION ---

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(26.1445, 91.7362),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    Radar.setUserId(widget.employee.id);
    Radar.setDescription(widget.employee.displayName);
    _setupRadarListeners();
    _styleFuture = _readStyle();
    _initializeFirstTime();
  }

  @override
  void didUpdateWidget(covariant EmployeeJourneyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialJourneyData != oldWidget.initialJourneyData &&
        widget.initialJourneyData != null) {
      debugPrint(
          "--- didUpdateWidget TRIGGERED: A new journey has been started! ---");
      _processNewJourneyData(widget.initialJourneyData!);
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    // --- MODIFIED: Cancel new stream and timer ---
    _positionStreamSubscription?.cancel();
    _radarArrivalCheckTimer?.cancel();
    // --- END MODIFICATION ---
    if (_isJourneyActive) {
      _stopJourney(); // Renamed function
    }
    super.dispose();
  }

  Future<void> _launchGoogleMapsNavigation() async {
    if (_destinationLocation == null) {
      _showError("Destination not set.");
      return;
    }
    final lat = _destinationLocation!.latitude;
    final lng = _destinationLocation!.longitude;
    final url = Uri.parse('google.navigation:q=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      _showError("Could not open Google Maps. Is it installed?");
    }
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNearArrivalNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'near_arrival_channel', 'Near Arrival Notifications',
        channelDescription: 'Notifies when you are close to your destination',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true);
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
        0,
        'Approaching Destination',
        'You are about to reach ${_destinationController.text}.',
        platformDetails);
  }

  Future<void> _showTrackingNotification() async {
    const int trackingNotificationId = 1;
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tracking_channel',
      'Tracking Notifications',
      channelDescription:
          'Shows when your location is being tracked for a journey.',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // This is key for the foreground service
      autoCancel: false,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
        trackingNotificationId,
        'Journey in Progress',
        'Your location is being actively tracked.',
        platformDetails);
  }

  Future<void> _cancelTrackingNotification() async {
    const int trackingNotificationId = 1;
    await flutterLocalNotificationsPlugin.cancel(trackingNotificationId);
  }

  Future<void> _initializeFirstTime() async {
    // This gets the *first* position and moves the camera
    await _determinePositionAndMoveCamera();
    // This starts the *continuous* stream for all future updates
    _startLocationStream();

    if (widget.initialJourneyData != null) {
      _processNewJourneyData(widget.initialJourneyData!);
    }
  }

  // --- NEW FUNCTION: Starts the continuous location stream ---
  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best, // Highest accuracy
      distanceFilter: 1, // Update every 1 meter moved
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(_onPositionUpdate, onError: (e) {
      debugPrint("Error in location stream: $e");
    });
  }

  // --- NEW FUNCTION: The new "heart" of the tracking logic ---
  // This runs on EVERY single position update from the GPS
  void _onPositionUpdate(Position position) {
    _currentUserLocation = LatLng(position.latitude, position.longitude);

    // --- Part 1: Always update the UI (the seamless blue dot) ---
    if (mounted) {
      _drawUserLocationPointer(_currentUserLocation!);
    }

    // --- Part 2: Only run journey logic if a journey is active ---
    if (!_isJourneyActive) {
      return;
    }

    // --- Part 3: In-house Distance Calculation ---
    if (_lastRecordedPosition != null) {
      // Calculate straight-line distance since last point
      final double movement = Geolocator.distanceBetween(
        _lastRecordedPosition!.latitude,
        _lastRecordedPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Only add distance if movement is "real" (e.g., > 2 meters) to filter GPS jitter
      if (movement > 2.0) {
        _totalDistanceTravelled += movement; // Add the free, calculated distance
        _lastRecordedPosition = position;
        _routeTaken.add(_currentUserLocation!);

        _updateTravelledPolyline();
      }
    } else {
      // This is the first point of the journey
      _lastRecordedPosition = position;
    }

    // --- Part 4: In-house Near Arrival Check ---
    if (_destinationLocation != null && !_isNearDestinationNotified) {
      final double distanceToDestination = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );
      if (distanceToDestination < 500) {
        _showNearArrivalNotification();
        _isNearDestinationNotified = true;
      }
    }

    // --- Part 5: Update Distance Text ---
    if (mounted) {
      setState(() {
        final distanceKm = _totalDistanceTravelled / 1000.0;
        _originController.text =
            "Distance: ${distanceKm.toStringAsFixed(2)} km";
      });
    }
  }
  // --- END OF NEW FUNCTIONS ---

  void _processNewJourneyData(Map<String, dynamic> journeyData) async {
    final String? pjpId = journeyData['pjpId'] as String?;
    final LatLng? destination = journeyData['destination'] as LatLng?;
    final String? displayName = journeyData['displayName'] as String?;

    if (destination == null || displayName == null || pjpId == null) {
      _showError('Received invalid journey data from PJP.');
      return;
    }
    _currentPjpId = pjpId; // Crucial for the new arrival listener
    _routeTaken.clear();
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('route-taken-line');
      await controller.removeSource('route-taken-source');
    } catch (_) {}
    if (mounted) {
      setState(() {
        _destinationLocation = destination;
        _destinationController.text = displayName;
      });
    }
    await _getDirectionsAndDrawRoute();
    widget.onDestinationConsumed?.call();
  }

  // --- MODIFIED: Listens for user.entered_geofence matching the PJP ID ---
  void _setupRadarListeners() {
    Radar.onEvents((result) {
      // Only check for events if we are on an active journey
      if (!_isJourneyActive || _currentPjpId == null) return;

      final events = result['events'] as List<dynamic>?;
      if (events == null) return;

      final arrivalEvent = events.firstWhere(
        (event) =>
            event['type'] == 'user.entered_geofence' &&
            event['geofence'] != null &&
            event['geofence']['externalId'] ==
                _currentPjpId, // Check if we entered the *correct* geofence
        orElse: () => null,
      );

      if (arrivalEvent != null) {
        debugPrint("✅ Matched geofence arrival event!");
        _showDestinationArrivalNotification();
      }
    });
  }
  // --- END MODIFICATION ---

  // --- DELETED: The old _performPeriodicUpdate() function is gone. ---
  // Its logic is now in _onPositionUpdate()

  // --- NEW FUNCTION: Periodically calls Radar.trackOnce for arrival detection ---
  void _performRadarArrivalCheck() async {
    // --- FIX 2 (Part A) ---
    // We only need to check _isJourneyActive, since trackOnce() gets its own location
    if (!_isJourneyActive) {
      _radarArrivalCheckTimer?.cancel();
      return;
    }

    try {
      debugPrint("--- Calling Radar.trackOnce() for arrival check ---");

      // --- FIX 2 (Part B) ---
      // The error "0 expected, but 1 found" means we must call it with no arguments.
      await Radar.trackOnce();
      // --- END OF FIX 2 ---

      // The _setupRadarListeners will catch any events generated by this call
    } catch (e) {
      debugPrint("Error calling Radar.trackOnce: $e");
    }
  }
  // --- END NEW FUNCTION ---

  // --- MODIFIED: Renamed and simplified. No more Radar.startTrip ---
  void _startJourney() async {
    if (_isJourneyActive || _destinationLocation == null) return;

    _isNearDestinationNotified = false;
    _routeTaken.clear();

    try {
      // Get the first point to start distance calculation
      Position initialPosition =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _lastRecordedPosition = initialPosition;
      _routeTaken
          .add(LatLng(initialPosition.latitude, initialPosition.longitude));
    } catch (e) {
      _showError("Could not get initial location: $e");
      return;
    }

    _currentJourneyId =
        'JRN-${widget.employee.id}-${DateTime.now().millisecondsSinceEpoch}';

    // --- DELETED: Radar.startTrip() and tripOptions are gone ---

    try {
      _showTrackingNotification(); // This is our foreground service

      setState(() {
        _isJourneyActive = true;
        _totalDistanceTravelled = 0.0;
        _originController.text = "Journey in Progress (0.00 km)";
      });
      _showError("Journey Tracking Started!");

      // --- MODIFIED: Start the new timer for arrival checks ---
      _radarArrivalCheckTimer?.cancel();
      _radarArrivalCheckTimer = Timer.periodic(
          const Duration(seconds: 30), // Check every 30 seconds
          (_) => _performRadarArrivalCheck());
      // --- END MODIFICATION ---
    } catch (e) {
      _showError("Failed to start journey.");
    }
  }
  // --- END MODIFICATION ---

  // --- MODIFIED: Renamed and simplified. No more Radar.completeTrip ---
  void _stopJourney() async {
    // --- MODIFIED: Cancel the new timer ---
    _radarArrivalCheckTimer?.cancel();
    // --- END MODIFICATION ---
    _cancelTrackingNotification();

    if (!_isJourneyActive) return;

    // --- DELETED: Radar.completeTrip() is gone ---

    // --- KEPT: This logic is perfect and unchanged ---
    // Send ONE final tracking point with the total distance
    if (_lastRecordedPosition != null && _currentJourneyId != null) {
      final finalTrackingPoint = GeoTrackingPoint(
        userId: int.parse(widget.employee.id),
        journeyId: _currentJourneyId!,
        latitude: _lastRecordedPosition!.latitude,
        longitude: _lastRecordedPosition!.longitude,
        totalDistanceTravelled:
            _totalDistanceTravelled, // Send the final calculated distance
        isActive: false,
        locationType: 'FINAL_STOP_SUMMARY',
      );
      // This is the only time we send geo-tracking data to the server
      _apiService.sendGeoTrackingPoint(finalTrackingPoint);
    }
    // --- END of kept logic ---

    if (_currentPjpId != null) {
      try {
        await _apiService.updatePjp(_currentPjpId!, {'status': 'completed'});
        debugPrint("✅ PJP status updated to completed.");
      } catch (e) {
        debugPrint("❌ Failed to update PJP status to completed: $e");
      }
    }

    final finalDistanceKm = _totalDistanceTravelled / 1000.0;
    if (mounted) {
      setState(() {
        _isJourneyActive = false;
        _currentJourneyId = null;
        _currentPjpId = null;
        _originController.text =
            "Journey Complete (${finalDistanceKm.toStringAsFixed(2)} km)";
      });
    }
    _showError(
        "Journey Ended. Total distance: ${finalDistanceKm.toStringAsFixed(2)} km.");
  }
  // --- END MODIFICATION ---

  void _showDestinationArrivalNotification() {
    if (!mounted || !_isJourneyActive) return;
    _stopJourney(); // Renamed function
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Destination Reached! 🎯'),
        content: Text(
            'You have arrived at ${_destinationController.text}. The journey has been automatically finalized.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }

  Future<void> _determinePositionAndMoveCamera() async {
    setState(() => _originController.text = "Checking permissions...");
    try {
      String? status = await Radar.getPermissionsStatus();
      if (status == 'DENIED' || status == 'NOT_DETERMINED') {
        // --- FIX 1 ---
        // The error "1 positional argument expected" means it needs the `true`
        status = await Radar.requestPermissions(true);
        // --- END OF FIX 1 ---
      }
      if (status != 'GRANTED_BACKGROUND' && status != 'GRANTED_FOREGROUND') {
        setState(() => _originController.text = 'Location permissions denied');
        _showError('Background location permissions are required for tracking.');
        return;
      }
      setState(() => _originController.text = "Fetching location...");
      // Gets the *very first* location fix
      Position position = await Geolocator.getCurrentPosition();
      _currentUserLocation = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _originController.text = "My Current Location");
      final controller = await _controllerCompleter.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentUserLocation!, zoom: 15.0),
      ));
      // Draws the *first* location dot. The stream will take over from here.
      _drawUserLocationPointer(_currentUserLocation!);
    } catch (e) {
      if (mounted)
        setState(() => _originController.text = "Failed to get location");
      _showError("Error getting location: $e");
    }
  }

  // This function is unchanged
  Future<void> _drawUserLocationPointer(LatLng point) async {
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('user-location-circle-outer');
      await controller.removeLayer('user-location-circle-inner');
      await controller.removeSource('user-location-source');
    } catch (_) {}
    await controller.addSource(
        'user-location-source',
        GeojsonSourceProperties(data: {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {},
              'geometry': {
                'type': 'Point',
                'coordinates': [point.longitude, point.latitude]
              }
            }
          ]
        }));
    await controller.addCircleLayer(
        'user-location-source',
        'user-location-circle-outer',
        const CircleLayerProperties(
            circleColor: '#FFFFFF', circleRadius: 12.0, circleOpacity: 0.9));
    await controller.addCircleLayer(
        'user-location-source',
        'user-location-circle-inner',
        const CircleLayerProperties(
            circleColor: '#3567FB', circleRadius: 8.0, circleOpacity: 1.0));
  }

  // This function is unchanged
  Future<void> _updateTravelledPolyline() async {
    if (_routeTaken.length < 2) return;
    final controller = await _controllerCompleter.future;
    try {
      await controller.removeLayer('route-taken-line');
      await controller.removeSource('route-taken-source');
    } catch (_) {}
    await controller.addSource(
        'route-taken-source',
        GeojsonSourceProperties(data: {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {},
              'geometry': {
                'type': 'LineString',
                'coordinates':
                    _routeTaken.map((p) => [p.longitude, p.latitude]).toList()
              }
            }
          ]
        }));
    await controller.addLineLayer(
        'route-taken-source',
        'route-taken-line',
        const LineLayerProperties(
            lineColor: '#FF0000',
            lineWidth: 6.0,
            lineOpacity: 0.6,
            lineCap: 'round',
            lineJoin: 'round'));
  }

  // This function is unchanged
  Future<void> _handleDestinationSubmit(String destinationAddress) async {
    if (_radarApiKey == null) return;
    if (_currentUserLocation == null) {
      _showError("Current location not available.");
      return;
    }
    final autocompleteUrl = Uri.parse(
        'https://api.radar.io/v1/autocomplete?query=$destinationAddress&near=${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}');
    try {
      final response = await http
          .get(autocompleteUrl, headers: {'Authorization': _radarApiKey});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['addresses'] != null && data['addresses'].isNotEmpty) {
          final lat = data['addresses'][0]['latitude'];
          final lon = data['addresses'][0]['longitude'];
          if (mounted) setState(() => _destinationLocation = LatLng(lat, lon));
          _getDirectionsAndDrawRoute();
        } else {
          _showError("Could not find location.");
        }
      } else {
        throw Exception('Failed to geocode address');
      }
    } catch (e) {
      _showError("Error finding destination.");
    }
  }

  // This function is unchanged
  Future<void> _getDirectionsAndDrawRoute() async {
    if (_currentUserLocation == null || _destinationLocation == null) return;
    final locations =
        '${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}|${_destinationLocation!.latitude},${_destinationLocation!.longitude}';
    final url = Uri.parse(
        'https://api.radar.io/v1/route/directions?locations=$locations&mode=car&units=metric&geometry=polyline5');
    try {
      final response =
          await http.get(url, headers: {'Authorization': _radarApiKey!});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final polylineString = data['routes'][0]['geometry']['polyline'];
        final polyline = PolylineCodec.decode(polylineString);
        final routePoints = polyline
            .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
            .toList();
        final controller = await _controllerCompleter.future;
        try {
          await controller.removeLayer('route-line');
          await controller.removeSource('route-source');
        } catch (_) {}
        await controller.addSource(
            'route-source',
            GeojsonSourceProperties(data: {
              'type': 'FeatureCollection',
              'features': [
                {
                  'type': 'Feature',
                  'properties': {},
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': routePoints
                        .map((p) => [p.longitude, p.latitude])
                        .toList()
                  }
                }
              ]
            }));
        await controller.addLineLayer(
            'route-source',
            'route-line',
            const LineLayerProperties(
                lineColor: '#3567FB',
                lineWidth: 5.0,
                lineOpacity: 0.8,
                lineCap: 'round',
                lineJoin: 'round'));
      } else {
        throw Exception('Failed to load directions');
      }
    } catch (e) {
      _showError("Error fetching route.");
    }
  }

  // This function is unchanged
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    debugPrint(message);
  }

  // This function is unchanged
  Future<String> _readStyle() async {
    if (_stadiaApiKey == null) throw Exception("Stadia Maps API key not found.");
    return jsonEncode({
      "version": 8,
      "sources": {
        "stadia": {
          "type": "raster",
          "tiles": [
            "https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}@2x.png?api_key=$_stadiaApiKey"
          ],
          "tileSize": 256
        }
      },
      "layers": [
        {
          "id": "stadia-layer",
          "source": "stadia",
          "type": "raster",
          "minzoom": 0,
          "maxzoom": 22
        }
      ]
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canStartJourney =
        _destinationLocation != null && !_isJourneyActive;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SizedBox.expand(
              child: FutureBuilder<String>(
                future: _styleFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Error loading map: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center),
                      ),
                    );
                  }
                  return MapLibreMap(
                    styleString: snapshot.data!,
                    initialCameraPosition: _initialCameraPosition,
                    onMapCreated: (controller) {
                      if (!_controllerCompleter.isCompleted) {
                        _controllerCompleter.complete(controller);
                      }
                    },
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLocationInputField(
                          controller: _originController,
                          hintText: 'Origin',
                          icon: Icons.my_location,
                          readOnly: true),
                      const SizedBox(height: 12),
                      _buildLocationInputField(
                          controller: _destinationController,
                          hintText: 'Enter Destination...',
                          icon: Icons.location_on,
                          readOnly: widget.initialJourneyData != null ||
                              _isJourneyActive,
                          onSubmitted: _handleDestinationSubmit),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 124,
              child: _StartJourneySlider(
                isJourneyActive: _isJourneyActive,
                // --- MODIFIED: Call renamed functions ---
                onSlideAction:
                    _isJourneyActive ? _stopJourney : _startJourney,
                // --- END MODIFICATION ---
                canStart: canStartJourney,
              ),
            ),
            if (_isJourneyActive)
              Positioned(
                left: 16,
                right: 16,
                bottom: 205,
                child: Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('NAVIGATE'),
                    onPressed: _launchGoogleMapsNavigation,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // This widget is unchanged
  Widget _buildLocationInputField(
      {required TextEditingController controller,
      required String hintText,
      required IconData icon,
      bool readOnly = false,
      void Function(String)? onSubmitted}) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          onSubmitted: onSubmitted,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
            prefixIcon: Icon(icon, size: 22, color: Colors.black54),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
          ),
        ),
      ),
    );
  }
}

// This widget is unchanged
class _StartJourneySlider extends StatelessWidget {
  final bool isJourneyActive;
  final VoidCallback onSlideAction;
  final bool canStart;

  const _StartJourneySlider({
    required this.isJourneyActive,
    required this.onSlideAction,
    required this.canStart,
  });

  @override
  Widget build(BuildContext context) {
    final String slideText =
        isJourneyActive ? 'SLIDE TO END JOURNEY' : 'SLIDE TO START JOURNEY';
    final Color outerColor = isJourneyActive
        ? Colors.redAccent.withAlpha(230)
        : Theme.of(context).colorScheme.primary.withAlpha(230);
    final Icon sliderIcon = isJourneyActive
        ? const Icon(Icons.stop)
        : const Icon(Icons.arrow_forward_ios);
    final bool isEnabled = canStart || isJourneyActive;

    return SlideAction(
      onSubmit: isEnabled
          ? () {
              onSlideAction();
              return null;
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Please set a destination before starting.'),
                  backgroundColor: Colors.orange));
              return null;
            },
      innerColor: Colors.white,
      outerColor: isEnabled ? outerColor : Colors.grey.withOpacity(0.75),
      sliderButtonIcon: sliderIcon,
      text: isEnabled ? slideText : 'DESTINATION NOT SET',
      enabled: isEnabled,
      textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5),
      borderRadius: 16,
      elevation: 0,
      height: 65,
    );
  }
}