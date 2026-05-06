import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_panel.dart';
import '../widgets/neon_button.dart';

class FindClinicPage extends StatelessWidget {
  const FindClinicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EDEA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF00897B), size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Find the Clinic',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text)),
                        Text('Location & contact info',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Map placeholder
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4EDEA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFB2DFDB), width: 0.8),
                  ),
                  child: Stack(
                    children: [
                      // Grid lines to suggest a map
                      CustomPaint(
                        size: const Size(double.infinity, 200),
                        painter: _MapGridPainter(),
                      ),
                      // Pin
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00897B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_hospital_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            CustomPaint(
                              size: const Size(14, 8),
                              painter: _PinTailPainter(),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF00897B)
                                          .withOpacity(0.15),
                                      blurRadius: 8)
                                ],
                              ),
                              child: const Text('DentalCare Clinic',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF004D40))),
                            ),
                          ],
                        ),
                      ),
                      // Open in maps button
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00897B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text('Open in Maps',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Address + directions
                NeonPanel(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00897B).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: Color(0xFF00897B), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Address',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                                Text('12 Rue Didouche Mourad, Sétif',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF004D40))),
                                Text('Sétif, Algeria 19000',
                                    style: TextStyle(
                                        color: Color(0xFF26A69A),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      NeonButton(
                        label: 'Get Directions',
                        icon: Icons.directions_rounded,
                        height: 46,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Contact info
                NeonPanel(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF004D40))),
                      const SizedBox(height: 14),
                      _contactRow(
                        Icons.phone_rounded,
                        'Phone',
                        '+213 36 84 00 00',
                        const Color(0xFF00897B),
                        onTap: () {},
                      ),
                      const Divider(color: Color(0xFFB2DFDB), height: 20),
                      _contactRow(
                        Icons.mail_rounded,
                        'Email',
                        'contact@dentalcare.dz',
                        const Color(0xFF00ACC1),
                        onTap: () {},
                      ),
                      const Divider(color: Color(0xFFB2DFDB), height: 20),
                      _contactRow(
                        Icons.language_rounded,
                        'Website',
                        'www.dentalcare.dz',
                        const Color(0xFF26A69A),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Working hours
                NeonPanel(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              color: Color(0xFF00897B), size: 18),
                          SizedBox(width: 8),
                          Text('Working Hours',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF004D40))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _hoursRow('Saturday – Wednesday', '8:00 AM – 5:00 PM', true),
                      const SizedBox(height: 8),
                      _hoursRow('Thursday', '8:00 AM – 12:00 PM', true),
                      const SizedBox(height: 8),
                      _hoursRow('Friday', 'Closed', false),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Emergency note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.red.withOpacity(0.25), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emergency_rounded,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'For dental emergencies outside working hours, call +213 36 84 00 01',
                          style: TextStyle(
                              color: Colors.red, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value, Color color,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF004D40))),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: color.withOpacity(0.6)),
        ],
      ),
    );
  }

  Widget _hoursRow(String day, String hours, bool isOpen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(day,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF004D40))),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isOpen ? const Color(0xFF00897B) : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(hours,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isOpen ? const Color(0xFF004D40) : Colors.red)),
          ],
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00897B).withOpacity(0.08)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Simulate a road
    final roadPaint = Paint()
      ..color = const Color(0xFF00897B).withOpacity(0.15)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(0, size.height * 0.55),
        Offset(size.width, size.height * 0.55),
        roadPaint);
    canvas.drawLine(
        Offset(size.width * 0.45, 0),
        Offset(size.width * 0.45, size.height),
        roadPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00897B)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
