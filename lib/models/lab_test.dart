class LabTest {
  final String code;      // مثل WBC, MCV...
  final String name;      // الاسم للعرض
  final double value;
  final double refMin;
  final double refMax;
  LabTest({
    required this.code,
    required this.name,
    required this.value,
    required this.refMin,
    required this.refMax,
  });
}
