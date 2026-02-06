import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdfx/pdfx.dart';

class ReportItem {
  final String title;
  final String dateLabel;
  final String iconPath;
  final Color backgroundColor;
  final String assetPdfPath;

  ReportItem({
    required this.title,
    required this.dateLabel,
    required this.iconPath,
    required this.backgroundColor,
    required this.assetPdfPath,
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

  String? _resolvePatientId() {
    if (widget.patientId != null && widget.patientId!.trim().isNotEmpty) {
      return widget.patientId;
    }
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// نجيب reportFileName (وإن وجد reportDate) ونسوي ReportItem واحد
  Future<ReportItem?> _loadReportItem() async {
    final id = _resolvePatientId();
    if (id == null) {
      debugPrint('❌ No patient id (not logged in)');
      return null;
    }

    final doc = await FirebaseFirestore.instance
        .collection('patient_profiles')
        .doc(id)
        .get();

    if (!doc.exists) {
      debugPrint('❌ patient_profiles/$id does not exist');
      return null;
    }

    final data = doc.data();
    if (data == null) return null;

    
    final String? fileName = data['reportFileName'] as String?;
    if (fileName == null || fileName.trim().isEmpty) {
      debugPrint('⚠ reportFileName is null/empty');
      return null;
    }

    
    String dateLabel = 'Date: -';
    final dateField = data['reportDate'];
    if (dateField is Timestamp) {
      final d = dateField.toDate();
      dateLabel =
          'Date: ${d.day.toString().padLeft(2, '0')} '
          '${_monthName(d.month)} '
          '${d.year}';
    }

   
    const folder = 'assets/';
    final assetPath = fileName.startsWith('assets/')
        ? fileName
        : '$folder$fileName';

    debugPrint('📄 PDF asset path: $assetPath');

    return ReportItem(
      title: 'Lab 1',                
      dateLabel: dateLabel,         
      iconPath: 'assets/blood_test.png',
      backgroundColor: const Color(0xFF5FAAB1),
      assetPdfPath: assetPath,
    );
  }

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
                      'Lab Report',
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: _FilterButton(
                              label: 'Filter by date',
                              onTap: null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: _FilterButton(
                              label: 'Type',
                              onTap: null,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    
                    Expanded(
                      child: FutureBuilder<ReportItem?>(
                        future: _loadReportItem(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snap.hasError) {
                            return Center(
                              child: Text('Error: ${snap.error}'),
                            );
                          }

                          final item = snap.data;
                          if (item == null) {
                            return const Center(
                              child: Text(
                                'No lab report found for this patient.',
                                style: TextStyle(fontSize: 16),
                              ),
                            );
                          }

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            children: [
                              _ReportCard(
                                report: item,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => LabPdfViewerScreen(
                                        title: item.title,
                                        assetPath: item.assetPdfPath,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
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
                          _BackBtn(),
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

  String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (m < 1 || m > 12) return '--';
    return names[m - 1];
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
      decoration: const BoxDecoration(
        color: Color(0xFF4C6EA0),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _FilterButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF6B8CAE),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: report.backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
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
                  Text(
                    report.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.dateLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // View button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.visibility_outlined,
                    color: Colors.white.withOpacity(0.9),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LabPdfViewerScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const LabPdfViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<LabPdfViewerScreen> createState() => _LabPdfViewerScreenState();
}

class _LabPdfViewerScreenState extends State<LabPdfViewerScreen> {
  late PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    debugPrint('📄 opening asset: ${widget.assetPath}');
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openAsset(widget.assetPath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: PdfViewPinch(
        controller: _pdfController,
      ),
    );
  }
}
