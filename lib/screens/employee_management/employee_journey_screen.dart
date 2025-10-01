import 'dart:async';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
// IMPORTED: The new map and location packages
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class EmployeeJourneyScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeJourneyScreen({super.key, required this.employee});

  @override
  State<EmployeeJourneyScreen> createState() => _EmployeeJourneyScreenState();
}

class _EmployeeJourneyScreenState extends State<EmployeeJourneyScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;

  // --- DYNAMIC STATE VARIABLES ---
  LatLng? _currentLocation;
  final List<LatLng> _routePoints = [];
  final List<Marker> _markers = [];
  double _totalDistance = 0.0;
  // State variable to track the map's current zoom level.
  double _currentZoom = 12.5;

  // Mock destination location
  static final LatLng _pjpLocation = LatLng(26.1824, 91.7538); // Guwahati

  @override
  void initState() {
    super.initState();
    _startJourney();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startJourney() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission is required.')));
        return;
      }
    }

    try {
      Position initialPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final initialLatLng = LatLng(initialPosition.latitude, initialPosition.longitude);

      setState(() {
        _currentLocation = initialLatLng;
        _routePoints.add(initialLatLng);
        _markers.add(_buildMarker(initialLatLng, Icons.person_pin_circle, Colors.blue));
        _markers.add(_buildMarker(_pjpLocation, Icons.location_on, Colors.red));
      });

      _mapController.move(initialLatLng, 15);
    } catch (e) {
      debugPrint("Error getting initial location: $e");
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        if (_routePoints.isNotEmpty) {
          final lastPoint = _routePoints.last;
          final distance = Geolocator.distanceBetween(lastPoint.latitude, lastPoint.longitude, newLocation.latitude, newLocation.longitude);
          _totalDistance += distance;
        }
        _currentLocation = newLocation;
        _routePoints.add(newLocation);

        _markers.removeWhere((m) => m.key == const Key('currentLocation'));
        _markers.add(_buildMarker(newLocation, Icons.person_pin_circle, Colors.blue, key: const Key('currentLocation')));
      });
      _mapController.move(newLocation, _currentZoom);
    });
  }

  Marker _buildMarker(LatLng point, IconData icon, Color color, {Key? key}) {
    return Marker(
      key: key,
      point: point,
      width: 80,
      height: 80,
      child: Icon(icon, color: color, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _pjpLocation,
            initialZoom: _currentZoom,
            // FIXED: Removed the unnecessary null check.
            onPositionChanged: (position, hasGesture) {
              _currentZoom = position.zoom;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  color: Colors.blueAccent,
                  strokeWidth: 4.0,
                ),
              ],
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildLocationInputField('From', _currentLocation != null ? 'My Current Location' : 'Getting location...'),
                const SizedBox(height: 8),
                _buildLocationInputField('To', 'PJP Destination'),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 100,
          child: _buildDetailsCard(),
        ),
        const Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: _StartJourneyButton(),
        ),
      ],
    );
  }

  Widget _buildLocationInputField(String label, String value) {
    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Text("$label:", style: const TextStyle(color: Colors.white70)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final distanceInKm = (_totalDistance / 1000).toStringAsFixed(1);
    return LiquidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PJP: Sharma Traders', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$distanceInKm km traveled', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text('Navigate'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _StartJourneyButton extends StatelessWidget {
  const _StartJourneyButton();

  @override
  Widget build(BuildContext context) {
    return SlideAction(
      onSubmit: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journey tracking started!')),
        );
      },
      innerColor: Colors.white,
      outerColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
      sliderButtonIcon: const Icon(Icons.arrow_forward),
      text: 'START JOURNEY',
      textStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      borderRadius: 16,
      elevation: 0,
      height: 60,
    );
  }
}

