import 'dart:async';
import 'dart:convert';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:polyline_codec/polyline_codec.dart';

class EmployeeJourneyScreen extends StatefulWidget {
  final Employee employee;
  // --- FIXED: Added the required parameters to the constructor ---
  final String? initialDestination;
  final VoidCallback? onDestinationConsumed;

  const EmployeeJourneyScreen({
    super.key,
    required this.employee,
    this.initialDestination,
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
  final String? _radarApiKey = dotenv.env['RADAR_PUBLISHABLE_KEY'];

  LatLng? _currentUserLocation;
  LatLng? _destinationLocation;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(26.1445, 91.7362),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _styleFuture = _readStyle();
    // --- UPDATED: Centralized initialization logic ---
    _initializeJourney();
  }

  // --- NEW: This method handles the full initialization logic ---
  Future<void> _initializeJourney() async {
    // First, get the user's current location
    await _determinePositionAndMoveCamera();

    // THEN, if an initial destination was passed from the PJP screen, process it
    if (widget.initialDestination != null && widget.initialDestination!.isNotEmpty) {
      _destinationController.text = widget.initialDestination!;
      // Automatically trigger the search and route drawing
      await _handleDestinationSubmit(widget.initialDestination!);
      // Inform the NavScreen that the destination has been used
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
    await controller.addSource(
      'user-location-source',
      GeojsonSourceProperties(
        data: {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {},
              'geometry': {
                'type': 'Point',
                'coordinates': [point.longitude, point.latitude],
              }
            }
          ]
        },
      ),
    );
    await controller.addCircleLayer(
      'user-location-source',
      'user-location-circle-outer',
      const CircleLayerProperties(
        circleColor: '#FFFFFF', circleRadius: 12.0, circleOpacity: 0.9),
    );
    await controller.addCircleLayer(
      'user-location-source',
      'user-location-circle-inner',
      const CircleLayerProperties(
        circleColor: '#3567FB', circleRadius: 8.0, circleOpacity: 1.0),
    );
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
    final autocompleteUrl = Uri.parse(
        'https://api.radar.io/v1/autocomplete?query=$destinationAddress&near=${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}');
    try {
      final response = await http.get(
        autocompleteUrl,
        headers: {'Authorization': _radarApiKey!},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['addresses'] != null && data['addresses'].isNotEmpty) {
          final lat = data['addresses'][0]['latitude'];
          final lon = data['addresses'][0]['longitude'];
          setState(() {
            _destinationLocation = LatLng(lat, lon);
          });
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
    final locations =
        '${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}|${_destinationLocation!.latitude},${_destinationLocation!.longitude}';
    final url = Uri.parse(
        'https://api.radar.io/v1/route/directions?locations=$locations&mode=car&units=metric&geometry=polyline5');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': _radarApiKey!},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final polylineString = data['routes'][0]['geometry']['polyline'];
        final polyline = PolylineCodec.decode(polylineString);
        final routePoints = polyline
            .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
            .toList();
        final controller = await _controllerCompleter.future;
        await controller.removeLayer('route-line');
        await controller.removeSource('route-source');
        await controller.addSource(
          'route-source',
          GeojsonSourceProperties(
            data: {
              'type': 'FeatureCollection',
              'features': [
                {
                  'type': 'Feature',
                  'properties': {},
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': routePoints
                        .map((p) => [p.longitude, p.latitude])
                        .toList(),
                  }
                }
              ]
            },
          ),
        );
        await controller.addLineLayer(
          'route-source',
          'route-line',
          const LineLayerProperties(
            lineColor: '#3567FB',
            lineWidth: 5.0,
            lineOpacity: 0.8,
            lineCap: 'round',
            lineJoin: 'round',
          ),
        );
      } else {
        throw Exception('Failed to load directions: ${response.body}');
      }
    } catch (e) {
      _showError("Error fetching route: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    debugPrint(message);
  }

  Future<String> _readStyle() async {
    if (_stadiaApiKey == null) {
      throw Exception("Stadia Maps API key not found in your .env file");
    }
    final styleJson = {
      "version": 8,
      "sources": {
        "stadia": {
          "type": "raster",
          "tiles": [
            "https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}@2x.png?api_key=$_stadiaApiKey"
          ],
          "tileSize": 256,
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
    };
    return jsonEncode(styleJson);
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<String>(
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
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildLocationInputField(
                  controller: _originController,
                  hintText: 'Origin',
                  icon: Icons.my_location,
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                _buildLocationInputField(
                  controller: _destinationController,
                  hintText: 'Enter Destination...',
                  icon: Icons.location_on,
                  readOnly: false,
                  onSubmitted: _handleDestinationSubmit,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 124,
          child: _StartJourneySlider(),
        ),
      ],
    );
  }

  Widget _buildLocationInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool readOnly = false,
    void Function(String)? onSubmitted,
  }) {
    return SizedBox(
      height: 60,
      child: LiquidGlassCard(
        child: Center(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onSubmitted: onSubmitted,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withAlpha(179)),
              prefixIcon: Icon(icon, size: 22, color: Colors.white70),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _StartJourneySlider extends StatelessWidget {
  const _StartJourneySlider();

  @override
  Widget build(BuildContext context) {
    return SlideAction(
      onSubmit: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journey has started!')),
        );
        return null;
      },
      innerColor: Colors.white,
      outerColor: Theme.of(context).colorScheme.primary.withAlpha(230),
      sliderButtonIcon: const Icon(Icons.arrow_forward_ios),
      text: 'SLIDE TO START JOURNEY',
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      borderRadius: 16,
      elevation: 0,
      height: 65,
    );
  }
}

