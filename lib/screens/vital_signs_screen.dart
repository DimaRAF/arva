import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // 1. استيراد حزمة الرسوم البيانية

// هذا الكلاس يمثل شاشة عرض العلامات الحيوية
class VitalSignsScreen extends StatelessWidget {
  const VitalSignsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F7), // لون الخلفية الرئيسي
      body: SafeArea(
        child: ListView( // استخدام ListView لتجنب مشاكل المساحة
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildHeartRateCard(),
            const SizedBox(height: 16),
            _buildVitalsGrid(),
            const SizedBox(height: 16),
            _buildPatientInfoCard(),
            const SizedBox(height: 24),
            _buildActivityChartCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- دوال بناء أجزاء الواجهة ---

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Vital signs',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF22364B)),
        ),
        CircleAvatar(
          backgroundColor: Color(0xFF4C6EA0),
          child: Icon(Icons.arrow_forward, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildHeartRateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC2E8E8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Heart Rate', style: TextStyle(color: Color(0xFF22364B), fontSize: 16)),
              const SizedBox(height: 8),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('96', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF22364B))),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0, left: 4),
                    child: Text('bpm', style: TextStyle(color: Color(0xFF22364B), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text('Normal', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 120,
            height: 60,
            child: CustomPaint(
              painter: HeartbeatPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsGrid() {
    return Row(
      children: [
        Expanded(child: _buildVitalCard(icon: Icons.bloodtype, iconColor: Colors.red, title: 'Blood Pressure', value: '110/70 mmHg', status: 'Normal', color: const Color(0xFFFADADD))),
        const SizedBox(width: 12),
        Expanded(child: _buildVitalCard(icon: Icons.thermostat, iconColor: Colors.green, title: 'Temperature', value: '37°C', status: 'Normal', color: const Color(0xFFD4EFDF))),
        const SizedBox(width: 12),
        Expanded(child: _buildVitalCard(icon: Icons.air, iconColor: Colors.blue, title: 'Oxygen Level', value: '99%', status: 'Normal', color: const Color(0xFFD6EAF8))),
      ],
    );
  }
  
  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF6A8EAF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 30, color: Color(0xFF4C6EA0)),
          ),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("AHMAD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text("Room 16", style: TextStyle(color: Colors.white70)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActivityChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Vital signs for last 24 hour", style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("Activity Growth", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _buildLineChartBarData(spots: const [FlSpot(0, 70), FlSpot(1, 80), FlSpot(2, 60), FlSpot(3, 90), FlSpot(4, 75)], color: Colors.red),
                  _buildLineChartBarData(spots: const [FlSpot(0, 40), FlSpot(1, 45), FlSpot(2, 35), FlSpot(3, 50), FlSpot(4, 42)], color: Colors.green),
                  _buildLineChartBarData(spots: const [FlSpot(0, 100), FlSpot(1, 95), FlSpot(2, 98), FlSpot(3, 92), FlSpot(4, 96)], color: Colors.blue),
                ],
              ),
            ),
          ),
           const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendItem(color: Colors.red, text: 'Blood Pressure'),
              _LegendItem(color: Colors.green, text: 'Temperature'),
              _LegendItem(color: Colors.blue, text: 'Oxygen Level'),
            ],
          )
        ],
      ),
    );
  }
  
  LineChartBarData _buildLineChartBarData({required List<FlSpot> spots, required Color color}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
  
  Widget _buildVitalCard({required IconData icon, required Color iconColor, required String title, required String value, required String status, required Color color}) {
     return Container(
      padding: const EdgeInsets.all(12),
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
            child: Text(status, style: const TextStyle(color: Colors.green, fontSize: 12)),
          ),
        ],
      ),
    );
  }
  
   Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Heart'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Document'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      currentIndex: 1, // القلب هو المحدد
      selectedItemColor: const Color(0xFF4C6EA0),
    );
  }
}

// كلاس مساعد لرسم مؤشر نبضات القلب
class HeartbeatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22364B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width * 0.2, size.height / 2)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.6, size.height / 2)
      ..lineTo(size.width, size.height / 2);
      
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}