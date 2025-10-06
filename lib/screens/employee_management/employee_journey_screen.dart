import 'dart:async';
import 'dart:convert';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/models/geotracking_data_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:polyline_codec/polyline_codec.dart';
import 'package:slide_to_act/slide_to_act.dart';

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

  LatLng? _currentUserLocation;
  LatLng? _destinationLocation;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(26.1445, 91.7362),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    Radar.setUserId(widget.employee.id);
    Radar.setDescription(widget.employee.displayName);
    _setupRadarListeners();
    _styleFuture = _readStyle();
    _initializeJourney();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _stopJourneyWithRadar();
    super.dispose();
  }

  void _setupRadarListeners() {
    Radar.onLocation((result) {
      if (!_isJourneyActive || _currentJourneyId == null) return;
      final locationMap = result['location'] as Map?;
      if (locationMap != null) {
        final position = Position(
          latitude: locationMap['latitude'] as double,
          longitude: locationMap['longitude'] as double,
          accuracy: locationMap['accuracy'] as double? ?? 0.0,
          speed: locationMap['speed'] as double? ?? 0.0,
          timestamp: DateTime.now(),
          heading: locationMap['heading'] as double? ?? 0.0,
          altitude: locationMap['altitude'] as double? ?? 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        _calculateDistanceAndReport(position);
      }
    });

    Radar.onEvents((result) {
      final events = result['events'] as List<dynamic>?;
      if (events == null) return;
      final arrivalEvent = events.firstWhere(
        (event) => event['type'] == 'trip.arrived_at_destination_geofence',
        orElse: () => null,
      );
      if (arrivalEvent != null) {
        _showDestinationArrivalNotification();
      }
    });
  }

  void _calculateDistanceAndReport(Position position) async {
    if (!mounted || !_isJourneyActive) return;
    if (_lastRecordedPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastRecordedPosition!.latitude,
        _lastRecordedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _totalDistanceTravelled += distance;
    }
    _lastRecordedPosition = position;
    _drawUserLocationPointer(LatLng(position.latitude, position.longitude));
    final trackingPoint = GeoTrackingPoint(
      userId: int.parse(widget.employee.id),
      journeyId: _currentJourneyId!,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      destLat: _destinationLocation?.latitude,
      destLng: _destinationLocation?.longitude,
      totalDistanceTravelled: _totalDistanceTravelled,
      isActive: true,
      locationType: 'RADAR_GPS',
      altitude: position.altitude,
      heading: position.heading,
    );
    _apiService.sendGeoTrackingPoint(trackingPoint);
    setState(() {
      final distanceKm = _totalDistanceTravelled / 1000.0;
      _originController.text = "Distance: ${distanceKm.toStringAsFixed(2)} km";
    });
  }

  void _startJourneyWithRadar() async {
    if (_isJourneyActive || _destinationLocation == null) return;
    _currentJourneyId = 'JRN-${widget.employee.id}-${DateTime.now().millisecondsSinceEpoch}';
    try {
      Position initialPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _lastRecordedPosition = Position(
        latitude: initialPosition.latitude,
        longitude: initialPosition.longitude,
        timestamp: initialPosition.timestamp,
        accuracy: initialPosition.accuracy,
        altitude: initialPosition.altitude,
        heading: initialPosition.heading,
        speed: initialPosition.speed,
        speedAccuracy: initialPosition.speedAccuracy,
        altitudeAccuracy: initialPosition.altitudeAccuracy,
        headingAccuracy: initialPosition.headingAccuracy,
      );
    } catch (e) {
      _showError("Could not get initial location to start tracking: $e");
      return;
    }
    final tripOptions = {
      "externalId": _currentJourneyId!,
      "destinationLatitude": _destinationLocation!.latitude,
      "destinationLongitude": _destinationLocation!.longitude,
      "mode": 'car',
      "destinationGeofenceTag": 'pjp_destination',
    };
    try {
      await Radar.startTrip(tripOptions: tripOptions, trackingOptions: {'preset': 'continuous'});
      setState(() {
        _isJourneyActive = true;
        _originController.text = "Journey in Progress (0.00 km)";
      });
      _showError("Journey Tracking Started!");
    } catch (e) {
      _showError("Failed to start Radar trip tracking. Check native setup/permissions.");
      debugPrint("Radar startTrip Error: $e");
    }
  }

  void _stopJourneyWithRadar() async {
    if (!_isJourneyActive) return;
    try {
      await Radar.completeTrip();
    } catch (e) {
      debugPrint("Error completing Radar trip on dispose: $e");
    }
    
    if (_lastRecordedPosition != null && _currentJourneyId != null) {
      final finalTrackingPoint = GeoTrackingPoint(
        userId: int.parse(widget.employee.id),
        journeyId: _currentJourneyId!,
        latitude: _lastRecordedPosition!.latitude,
        longitude: _lastRecordedPosition!.longitude,
        totalDistanceTravelled: _totalDistanceTravelled,
        isActive: false,
        locationType: 'FINAL_STOP',
      );
      _apiService.sendGeoTrackingPoint(finalTrackingPoint);
    }
    final finalDistanceKm = _totalDistanceTravelled / 1000.0;
    if (mounted) {
      setState(() {
        _isJourneyActive = false;
        _currentJourneyId = null;
        _totalDistanceTravelled = 0.0;
        _lastRecordedPosition = null;
        _originController.text = "Journey Complete (${finalDistanceKm.toStringAsFixed(2)} km)";
      });
    }
    _showError("Journey Ended. Total distance: ${finalDistanceKm.toStringAsFixed(2)} km.");
  }

  void _showDestinationArrivalNotification() {
    if (!mounted || !_isJourneyActive) return;
    _stopJourneyWithRadar();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Destination Reached! 🎯'),
        content: const Text('You have arrived at your destination geofence. The journey has been automatically finalized.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _initializeJourney() async {
    await _determinePositionAndMoveCamera();
    
    if (widget.initialJourneyData != null) {
      final LatLng destination = widget.initialJourneyData!['destination'];
      final String displayName = widget.initialJourneyData!['displayName'];
      
      if (mounted) {
        setState(() {
          _destinationLocation = destination;
          _destinationController.text = displayName;
        });
      }
      
      await _getDirectionsAndDrawRoute();
      widget.onDestinationConsumed?.call();
    }
  }

  Future<void> _determinePositionAndMoveCamera() async {
    bool serviceEnabled;
    LocationPermission permission;
    setState(() => _originController.text = "Checking permissions...");
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _originController.text = 'Location services are disabled.');
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _originController.text = 'Location permissions are denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _originController.text = 'Permissions permanently denied');
      return;
    }
    setState(() => _originController.text = "Fetching location...");
    try {
      Position position = await Geolocator.getCurrentPosition();
      _currentUserLocation = LatLng(position.latitude, position.longitude);
      setState(() => _originController.text = "My Current Location");
      final controller = await _controllerCompleter.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentUserLocation!, zoom: 15.0),
      ));
      _drawUserLocationPointer(_currentUserLocation!);
    } catch (e) {
      setState(() => _originController.text = "Failed to get location");
      debugPrint("Geolocator error: $e");
    }
  }

  Future<void> _drawUserLocationPointer(LatLng point) async {
    final controller = await _controllerCompleter.future;
    await controller.removeLayer('user-location-circle-outer');
    await controller.removeLayer('user-location-circle-inner');
    await controller.removeSource('user-location-source');
    await controller.addSource('user-location-source', GeojsonSourceProperties(data: {'type': 'FeatureCollection', 'features': [{'type': 'Feature', 'properties': {}, 'geometry': {'type': 'Point', 'coordinates': [point.longitude, point.latitude]}}]}));
    await controller.addCircleLayer('user-location-source', 'user-location-circle-outer', const CircleLayerProperties(circleColor: '#FFFFFF', circleRadius: 12.0, circleOpacity: 0.9));
    await controller.addCircleLayer('user-location-source', 'user-location-circle-inner', const CircleLayerProperties(circleColor: '#3567FB', circleRadius: 8.0, circleOpacity: 1.0));
  }

  Future<void> _handleDestinationSubmit(String destinationAddress) async {
    if (_radarApiKey == null) {
      _showError("Radar API Key is not configured.");
      return;
    }
    if (_currentUserLocation == null) {
      _showError("Current location not available. Cannot search.");
      return;
    }
    final autocompleteUrl = Uri.parse('https://api.radar.io/v1/autocomplete?query=$destinationAddress&near=${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}');
    try {
      final response = await http.get(autocompleteUrl, headers: {'Authorization': _radarApiKey});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['addresses'] != null && data['addresses'].isNotEmpty) {
          final lat = data['addresses'][0]['latitude'];
          final lon = data['addresses'][0]['longitude'];
          setState(() => _destinationLocation = LatLng(lat, lon));
          _getDirectionsAndDrawRoute();
        } else {
          _showError("Could not find location: $destinationAddress");
        }
      } else {
        throw Exception('Failed to geocode address: ${response.body}');
      }
    } catch (e) {
      _showError("Error finding destination: $e");
    }
  }

  Future<void> _getDirectionsAndDrawRoute() async {
    if (_currentUserLocation == null || _destinationLocation == null) {
      _showError("Origin or destination is not set.");
      return;
    }
    final locations = '${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}|${_destinationLocation!.latitude},${_destinationLocation!.longitude}';
    final url = Uri.parse('https://api.radar.io/v1/route/directions?locations=$locations&mode=car&units=metric&geometry=polyline5');
    try {
      final response = await http.get(url, headers: {'Authorization': _radarApiKey!});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final polylineString = data['routes'][0]['geometry']['polyline'];
        final polyline = PolylineCodec.decode(polylineString);
        final routePoints = polyline.map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();
        final controller = await _controllerCompleter.future;
        await controller.removeLayer('route-line');
        await controller.removeSource('route-source');
        await controller.addSource('route-source', GeojsonSourceProperties(data: {'type': 'FeatureCollection', 'features': [{'type': 'Feature', 'properties': {}, 'geometry': {'type': 'LineString', 'coordinates': routePoints.map((p) => [p.longitude, p.latitude]).toList()}}]}));
        await controller.addLineLayer('route-source', 'route-line', const LineLayerProperties(lineColor: '#3567FB', lineWidth: 5.0, lineOpacity: 0.8, lineCap: 'round', lineJoin: 'round'));
      } else {
        throw Exception('Failed to load directions: ${response.body}');
      }
    } catch (e) {
      _showError("Error fetching route: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    debugPrint(message);
  }

  Future<String> _readStyle() async {
    if (_stadiaApiKey == null) throw Exception("Stadia Maps API key not found in your .env file");
    return jsonEncode({
      "version": 8,
      "sources": {"stadia": {"type": "raster", "tiles": ["https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}@2x.png?api_key=$_stadiaApiKey"], "tileSize": 256}},
      "layers": [{"id": "stadia-layer", "source": "stadia", "type": "raster", "minzoom": 0, "maxzoom": 22}]
    });
  }
  
  // --- BUILD METHOD MODIFIED TO FIX THE RED SCREEN ERROR ---
  @override
  Widget build(BuildContext context) {
    final bool canStartJourney = _destinationLocation != null && !_isJourneyActive;
    
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
                        child: Text('Error loading map: ${snapshot.error}', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
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
                      _buildLocationInputField(controller: _originController, hintText: 'Origin', icon: Icons.my_location, readOnly: true),
                      const SizedBox(height: 12),
                      _buildLocationInputField(controller: _destinationController, hintText: 'Enter Destination...', icon: Icons.location_on, readOnly: widget.initialJourneyData != null || _isJourneyActive, onSubmitted: _handleDestinationSubmit),
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
                onSlideAction: _isJourneyActive ? _stopJourneyWithRadar : _startJourneyWithRadar,
                canStart: canStartJourney,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationInputField({required TextEditingController controller, required String hintText, required IconData icon, bool readOnly = false, void Function(String)? onSubmitted}) {
    return SizedBox(
      height: 60,
      child: LiquidGlassCard(
        child: Center(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onSubmitted: onSubmitted,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(hintText: hintText, hintStyle: TextStyle(color: Colors.white.withAlpha(179)), prefixIcon: Icon(icon, size: 22, color: Colors.white70), border: InputBorder.none),
          ),
        ),
      ),
    );
  }
}

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
    final String slideText = isJourneyActive ? 'SLIDE TO END JOURNEY' : 'SLIDE TO START JOURNEY';
    final Color outerColor = isJourneyActive ? Colors.redAccent.withAlpha(230) : Theme.of(context).colorScheme.primary.withAlpha(230);
    final Icon sliderIcon = isJourneyActive ? const Icon(Icons.stop) : const Icon(Icons.arrow_forward_ios);
    final bool isEnabled = canStart || isJourneyActive;
    return SlideAction(
      onSubmit: isEnabled
          ? () {
              onSlideAction();
              return null;
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set a destination before starting.'), backgroundColor: Colors.orange));
              return null;
            },
      innerColor: Colors.white,
      outerColor: isEnabled ? outerColor : Colors.grey.withOpacity(0.5),
      sliderButtonIcon: sliderIcon,
      text: isEnabled ? slideText : 'DESTINATION NOT SET',
      enabled: isEnabled,
      textStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      borderRadius: 16,
      elevation: 0,
      height: 65,
    );
  }
}