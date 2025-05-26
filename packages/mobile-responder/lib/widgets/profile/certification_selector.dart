import 'package:flutter/material.dart';

class CertificationSelector extends StatelessWidget {
  final List<String> availableCertifications;
  final List<String> selectedCertifications;
  final Function(String, bool) onCertificationChanged;

  const CertificationSelector({
    super.key,
    required this.availableCertifications,
    required this.selectedCertifications,
    required this.onCertificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: availableCertifications.map((cert) {
          return CheckboxListTile(
            title: Text(cert),
            value: selectedCertifications.contains(cert),
            onChanged: (bool? value) {
              onCertificationChanged(cert, value ?? false);
            },
          );
        }).toList(),
      ),
    );
  }
}
