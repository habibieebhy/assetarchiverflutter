import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/widgets/reusableglasscard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// IMPORTED: The new packages for dialing and the swipe button.
import 'package:url_launcher/url_launcher.dart';
import 'package:slide_to_act/slide_to_act.dart';

// A simple model to hold the data for each PJP item
class _PjpItem {
  final String name;
  final String address;
  final String phone;

  _PjpItem({required this.name, required this.address, required this.phone});
}

class EmployeePJPScreen extends StatefulWidget {
  final Employee employee;
  const EmployeePJPScreen({super.key, required this.employee});

  @override
  State<EmployeePJPScreen> createState() => _EmployeePJPScreenState();
}

class _EmployeePJPScreenState extends State<EmployeePJPScreen> {
  // Mock data to populate the list, based on your design
  final List<_PjpItem> _pjpList = [
    _PjpItem(name: 'Sharma Traders', address: 'Plot 22, Industrial Area\nPhase 2, Jaipur', phone: '+919876543210'),
    _PjpItem(name: 'Verma Distributors', address: '100 Ring Road\nKanpur', phone: '+919876543211'),
    _PjpItem(name: 'Gupta & Co.', address: '8/4 Gandhi Nagar\nLucknow', phone: '+919876543212'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView.builder(
        // FIXED: Added top padding to account for the AppBar, so the first card is visible.
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        itemCount: _pjpList.length,
        itemBuilder: (context, index) {
          return _PjpCard(item: _pjpList[index])
              .animate()
              .fadeIn(duration: 500.ms, delay: (100 * index).ms)
              .slideY(begin: 0.2);
        },
      ),
    );
  }
}

// A dedicated widget for the PJP card UI
class _PjpCard extends StatelessWidget {
  final _PjpItem item;
  const _PjpCard({required this.item});

  // --- NEW: Helper function to launch the phone dialer ---
  Future<void> _launchDialer(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      // Show an error if the dialer can't be opened.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open dialer for $phoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: LiquidGlassCard(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(item.address, style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 8),
                      // UPDATED: Phone number is now a clickable button.
                      InkWell(
                        onTap: () => _launchDialer(item.phone, context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            item.phone,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.lightBlueAccent,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.lightBlueAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // UPDATED: Replaced the simple icon with a more realistic map thumbnail.
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          'https://placehold.co/160x160/334155/e2e8f0?text=Map',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade800),
                        ),
                        const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // UPDATED: Replaced the button with a real swipe-to-action widget.
            const _SwipeToStartAction(),
          ],
        ),
      ),
    );
  }
}

// --- NEW: The Swipe-to-Action widget using the 'slide_to_act' package ---
class _SwipeToStartAction extends StatelessWidget {
  const _SwipeToStartAction();

  @override
  Widget build(BuildContext context) {
    return SlideAction(
      onSubmit: () {
        // This code runs after a successful swipe.
        // We add a small delay so the user can see the animation finish.
        Future.delayed(const Duration(milliseconds: 500), () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Journey Started!')),
          );
        });
      },
      innerColor: Colors.white,
      outerColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      sliderButtonIcon: const Icon(Icons.arrow_forward),
      text: 'SWIPE TO START JOURNEY',
      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
      borderRadius: 12,
      elevation: 0,
      height: 56,
    );
  }
}

