import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class PerksPage extends StatelessWidget {
  const PerksPage({super.key});

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
                const Text('My Perks',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
                const Text('Your rewards and benefits',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),

                const SizedBox(height: 24),

                // Points card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F2A44), Color(0xFF0A1A2E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.neonCyan.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('Your Points',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14)),
                      const Text('1,250 pts',
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 40,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 0.6,
                          minHeight: 8,
                          backgroundColor:
                              AppColors.stroke,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                  AppColors.neonCyan),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('750 pts until Gold Level 🏆',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('Available Rewards',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
                const SizedBox(height: 12),

                _buildPerkCard('Free Checkup', '500 pts',
                    Icons.search_rounded, AppColors.neonTeal),
                const SizedBox(height: 12),
                _buildPerkCard('10% Discount', '300 pts',
                    Icons.discount_rounded, AppColors.neonCyan),
                const SizedBox(height: 12),
                _buildPerkCard('Free X-Ray', '800 pts',
                    Icons.image_rounded,
                    const Color(0xFF26A69A)),
                const SizedBox(height: 12),
                _buildPerkCard('Priority Booking', '1000 pts',
                    Icons.calendar_today_rounded, AppColors.tealDeep),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerkCard(
      String title, String points, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.text)),
                Text(points,
                    style: TextStyle(color: color, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Redeem',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}