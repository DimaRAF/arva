import 'package:flutter/material.dart';
import 'results_page.dart';

class ReportItem {
  final String title;
  final String date;
  final String iconPath;
  final Color backgroundColor;

  ReportItem({
    required this.title,
    required this.date,
    required this.iconPath,
    required this.backgroundColor,
  });
}

class MedicalReportsPage extends StatefulWidget {
  
  final String? patientId;

  const MedicalReportsPage({super.key, this.patientId});

  @override
  State<MedicalReportsPage> createState() => _MedicalReportsPageState();
}

class _MedicalReportsPageState extends State<MedicalReportsPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<ReportItem> reports = [
    ReportItem(
      title: 'Blood Test',
      date: '03 Mar 2025',
      iconPath: 'assets/blood_test.png',
      backgroundColor: const Color(0xFF5FAAB1),
    ),
    ReportItem(
      title: 'Lungs Check',
      date: '20 Feb 2025',
      iconPath: 'assets/lungs_check.png',
      backgroundColor: const Color(0xFFB695C0),
    ),
    ReportItem(
      title: 'Lab Culture',
      date: '11 Jan 2025',
      iconPath: 'assets/analysis.png',
      backgroundColor: const Color(0xFF5FAAB1),
    ),
    ReportItem(
      title: 'Genetic Analysis',
      date: '26 Dec 2024',
      iconPath: 'assets/DNA.png',
      backgroundColor: const Color(0xFFB695C0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5FAAB1),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: const [
                  Icon(Icons.folder_outlined, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Medical Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content container
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'search',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.close, color: Colors.grey[600]),
                              onPressed: _searchController.clear,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Filter buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Expanded(child: _FilterButton(label: 'Filter by date', onTap: () {})),
                          const SizedBox(width: 16),
                          Expanded(child: _FilterButton(label: 'Type', onTap: () {})),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Reports list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _ReportCard(
                              report: report,
                              onTap: () {
                               
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ResultsPage(
                                      patientId: widget.patientId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom navigation
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          // Back
                          _BackBtn(),
                          // Add (placeholder)
                          _AddBtn(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: const Icon(Icons.arrow_back, color: Color(0xFF4C6EA0), size: 28),
      ),
    );
  }
}

class _AddBtn extends StatelessWidget {
  const _AddBtn();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(color: Color(0xFF4C6EA0), shape: BoxShape.circle),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF6B8CAE), borderRadius: BorderRadius.circular(24)),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportItem report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: report.backgroundColor, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Image.asset(
                  report.iconPath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      const Icon(Icons.medical_services, color: Colors.white, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.title,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Date: ${report.date}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),
            // View button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Icon(Icons.visibility_outlined, color: Colors.white.withOpacity(0.9), size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
