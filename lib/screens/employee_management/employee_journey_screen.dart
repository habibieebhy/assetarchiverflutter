import 'dart:async';
import 'dart:convert';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:slide_to_act/slide_to_act.dart';

class EmployeeJourneyScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeJourneyScreen({super.key, required this.employee});

  @override
  State<EmployeeJourneyScreen> createState() => _EmployeeJourneyScreenState();
}

class _EmployeeJourneyScreenState extends State<EmployeeJourneyScreen> {
  // --- STATE VARIABLES ---
  late Future<String> _styleFuture;
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final String? _stadiaApiKey = dotenv.env['STADIA_API_KEY'];

  // Initial camera position set to Guwahati, Assam
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(26.1445, 91.7362),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    // Start loading the map style as soon as the screen is initialized
    _styleFuture = _readStyle();
    // Pre-fill the origin for demonstration
    _originController.text = "Current Location";
  }

  // Asynchronously loads the map style from Stadia Maps
  Future<String> _readStyle() async {
    if (_stadiaApiKey == null) {
      // This error will be caught by the FutureBuilder
      throw Exception("Stadia Maps API key not found in your .env file");
    }

    // Using a bright, clear map style from Stadia
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
    // The Stack allows us to layer UI elements on top of the map
    return Stack(
      children: [
        // --- MAP LAYER (BOTTOM) ---
        FutureBuilder<String>(
          future: _styleFuture,
          builder: (context, snapshot) {
            // Show a loading indicator while the map style is being fetched
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show an error message if the style fails to load
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading map: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // Once the style is loaded, display the map
            return MapLibreMap(
              // FIXED: The correct parameter name is 'styleString'.
              styleString: snapshot.data!,
              initialCameraPosition: _initialCameraPosition,
            );
          },
        ),

        // --- UI LAYER (TOP) ---
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Origin and Destination input fields
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

        // --- SLIDER LAYER (BOTTOM) ---
        const Positioned(
          left: 16,
          right: 16,
          bottom: 125,
          child: _StartJourneySlider(),
        ),
      ],
    );
  }

  // A reusable widget for the glass-style text fields
  Widget _buildLocationInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    // Using your custom LiquidGlassCard for a consistent UI
    return SizedBox(
      height: 60,
      child: LiquidGlassCard(
        child: Center(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Color.fromARGB(255, 6, 51, 124)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: const Color.fromARGB(255, 39, 66, 164).withAlpha(179)),
              prefixIcon: Icon(icon, size: 22),
              // Use the theme's input decoration but remove the default borderr
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}

// The "Swipe to Start" widget, kept separate for clarity
class _StartJourneySlider extends StatelessWidget {
  const _StartJourneySlider();

  @override
  Widget build(BuildContext context) {
    return SlideAction(
      onSubmit: () {
        // We can add the journey start logic here later
        // For now, it just shows a confirmation message
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

