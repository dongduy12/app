import 'package:flutter/material.dart';
import 'package:mobile_app/core/constants/colors.dart';
import 'pe_system_screen.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
              crossAxisCount: 2,//2 card mỗi dòng
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.0,
              children: [
                _buildFunctionCard(
                  context,
                  icon: Icons.qr_code_scanner,
                  label:'Search List',
                  onTap:(){
                    print('Navigating to PESystemScreen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PESystemScreen()),
                    );
                  },
                ),
                _buildFunctionCard(
                  context,
                  icon: Icons.run_circle,
                  label: 'Retest',
                  onTap: () {
                    print('Retest');
                    // Thêm logic cho card khác nếu cần
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang phát triển')),
                    );
                  },
                ),
              ],
          )
        ),
      ),
    );
  }

  Widget _buildFunctionCard(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64, // Icon lớn
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}