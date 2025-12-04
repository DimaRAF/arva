import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'medical_reports_page.dart';
import 'results_page.dart';

class MedicalReportHomeScreen extends StatelessWidget {
  final String? patientId;
  const MedicalReportHomeScreen({super.key, this.patientId});

  Future<void> _pickAndShowResult(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (picked == null) return;
    final Uint8List? bytes = picked.files.single.bytes;
    if (bytes == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsPage(pdfBytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 420;
    final circleSize = isSmall ? size.width * 0.72 : size.width * 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFF5FAAB1),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2C5360),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                        elevation: 6,
                        shadowColor: Colors.black26,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.close, size: 18, color: Color(0xFF355A66)),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

               
                SizedBox(
                  height: circleSize + 24,
                  child: Center(
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7F8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.all(isSmall ? 10 : 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Colors.white.withOpacity(0.08), Colors.transparent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 20),
                            child: Image.asset(
                              'assets/analysis.png',
                              fit: BoxFit.contain,
                              width: circleSize * 0.7,
                              height: circleSize * 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 90),

                // العنوان
                Text(
                  'Reading Medical Analysis',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 22 : 32,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 28),

                // الأزرار
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      _ActionButton(
                        leading: const _IconBox(
                          child: Image(image: AssetImage('assets/DNA.png')),
                        ),
                        label: 'Upload from Phone',
                        trailing: Container(
                          width: 40,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC6B4DE),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(Icons.upload_outlined, size: 20, color: Colors.white),
                        ),
                        onTap: () => _pickAndShowResult(context),           // اضغطي على الكرت
                        onTrailingTap: () => _pickAndShowResult(context),   // أو على السهم
                      ),
                      const SizedBox(height: 16),
                      _ActionButton(
                        leading: const _IconBox(
                          child: Image(image: AssetImage('assets/Hospital.png')),
                        ),
                        label: 'Last Report',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicalReportsPage(patientId: patientId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// (الدوال المساعدة)
class _ActionButton extends StatelessWidget {
  final Widget leading;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final VoidCallback? onTrailingTap;

  const _ActionButton({
    required this.leading,
    required this.label,
    this.trailing,
    this.onTrailingTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF003F5F), fontSize: 16),
              ),
            ),
            if (trailing != null)
              (onTrailingTap != null)
                  ? GestureDetector(onTap: onTrailingTap, child: trailing!)
                  : trailing!,
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final Widget child;
  const _IconBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF4C6EA0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: child),
    );
  }
}
