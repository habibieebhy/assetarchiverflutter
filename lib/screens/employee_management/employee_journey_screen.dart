import 'dart:async';
import 'dart:convert';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:slide_to_act/slide_to_act.dart';
// UPDATED: Removed Radar and imported the standard geolocator package.
import 'package:geolocator/geolocator.dart';

class EmployeeJourneyScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeJourneyScreen({super.key, required this.employee});

  @override
  State<EmployeeJourneyScreen> createState() => _EmployeeJourneyScreenState();
}

class _EmployeeJourneyScreenState extends State<EmployeeJourneyScreen> {
  // --- STATE VARIABLES ---
  final Completer<MapLibreMapController> _controllerCompleter = Completer();
  late Future<String> _styleFuture;
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final String? _stadiaApiKey = dotenv.env['STADIA_API_KEY'];

  // Initial camera position is a fallback until user location is found.
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(26.1445, 91.7362), // Guwahati, Assam
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _styleFuture = _readStyle();
    // UPDATED: Call the new function to get the device's GPS location.
    _determinePositionAndMoveCamera();
  }

  // REPLACED: This function now uses the 'geolocator' package to get the device's exact location.
  Future<void> _determinePositionAndMoveCamera() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _originController.text = "Checking permissions...";
    });

    // 1. Check if location services are enabled on the device.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _originController.text = 'Location services are disabled.';
      });
      return;
    }

    // 2. Check for permissions.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _originController.text = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _originController.text = 'Permissions permanently denied';
      });
      return;
    }

    // 3. If permissions are granted, get the current position.
    setState(() {
      _originController.text = "Fetching location...";
    });
    try {
      Position position = await Geolocator.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);

      // 4. Update the UI and animate the map to the user's location.
      setState(() {
        _originController.text = "My Current Location";
      });

      final controller = await _controllerCompleter.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: userLocation, zoom: 15.0),
      ));
    } catch (e) {
      setState(() {
        _originController.text = "Failed to get location";
      });
      debugPrint("Geolocator error: $e");
    }
  }

  // Asynchronously loads the map style from Stadia Maps
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
          "type": "raster",
          "source": "stadia",
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
                ),
                const SizedBox(height: 12),
                _buildLocationInputField(
                  controller: _destinationController,
                  hintText: 'Destination',
                  icon: Icons.location_on,
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 16,
          right: 16,
          bottom: 24, // Adjusted position for better layout
          child: _StartJourneySlider(),
        ),
      ],
    );
  }

  Widget _buildLocationInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return SizedBox(
      height: 60,
      child: LiquidGlassCard(
        child: Center(
          child: TextField(
            controller: controller,
            readOnly: true,
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

