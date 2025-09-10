import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _patientData = doc.data() as Map<String, dynamic>?;
          });
        }
      } catch (e) {
        print("Error fetching patient data: $e");
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3E5B7A))))
          : SingleChildScrollView(
              child: Column(
                children: [
                  
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      
                      Container(
                        height: 140,
                        width: double.infinity,
                        color: const Color(0xFF5FAAB1),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'search',
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  suffixIcon: const Icon(Icons.close, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      
                      Positioned(
                        top: 160, 
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4C6EA0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                                child: const Icon(Icons.person, size: 45, color: Color(0xFF3E5B7A)),
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("Hi,", style: TextStyle(color: Colors.white, fontSize: 18)),
                                  Text(
                                    _patientData?['username']?.toUpperCase() ?? 'USER',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              
                            ],
                          ),
                        ),
                      ),
                     
                    ],
                  ),
                  
                  
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 90, 20, 20), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      
                      children: [
                        
                        
                         const SizedBox(height: 30),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.3,
                          children: [
                            
                            _buildInfoCard(title: 'Blood Group', value: _patientData?['blood_group'] ?? '--', icon: Icons.bloodtype, color: const Color(0xFFFBE0E0), iconColor: Colors.red),
                            _buildInfoCard(title: 'Weight', value: '${_patientData?['weight'] ?? '--'} kg', icon: Icons.fitness_center, color: const Color(0xFFBFE0E2), iconColor: Colors.green.shade700),
                            _buildInfoCard(title: 'Height', value: '${_patientData?['height'] ?? '--'} cm', icon: Icons.height, color: const Color(0xFFBFE0E2), iconColor: Colors.green.shade700),
                            _buildInfoCard(title: 'Age', value: '${_patientData?['age'] ?? '--'}', icon: Icons.cake_outlined, color: const Color(0xFFE0E6F8), iconColor: Colors.blue.shade700),
                          ],
                        ),
                        const SizedBox(height: 30),
                        const Text("Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildServiceButton(imagePath: 'assets/analysis.png', label: 'analysis'),
                            _buildServiceButton(imagePath: 'assets/drugs.png', label: 'Drugs'),
                            _buildServiceButton(imagePath: 'assets/report.png', label: 'Report'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height:70,
      decoration: const BoxDecoration(
        color: Color(0xFF4C6EA0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(icon: Icons.home, index: 0),
          _buildNavItem(icon: Icons.search, index: 1),
          _buildNavItem(icon: Icons.person, index: 2),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: isSelected
          ? Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4C6EA0),
                ),
                child: Icon(icon, color: Colors.white, size: 40),
              ),
            )
          : Icon(icon, color: Colors.white.withOpacity(0.7), size: 30),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25)),
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
          Text(title, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildServiceButton({required String imagePath, required String label}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          width: 80, 
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Image.asset(imagePath),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
