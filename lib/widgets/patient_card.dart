// widgets/patient_card.dart
import 'package:flutter/material.dart';
import '../models/patient.dart';
import 'liquid_level_indicator.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;

  const PatientCard({Key? key, required this.patient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // Define the shadows for the soft, extruded look
    final List<BoxShadow> softShadows = [
      BoxShadow(
        color: isLight ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.4),
        offset: const Offset(5, 5),
        blurRadius: 10,
      ),
      BoxShadow(
        color: isLight ? Colors.white.withOpacity(0.7) : Colors.grey.shade800.withOpacity(0.5),
        offset: const Offset(-5, -5),
        blurRadius: 10,
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadows,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Side: Liquid Level Indicator
            SizedBox(
              width: 80,
              child: Center(
                child: LiquidLevelIndicator(level: patient.currentLiquidLevel),
              ),
            ),
            // Right Side: Patient Information
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildRateInfo(),
                    if (patient.hasAirBubble) _buildAirBubbleWarning(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Patient #${patient.patientId}',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            _StatusChip(isActive: patient.isActive),
          ],
        ),
        Text(
          patient.drugName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRateInfo() {
    return Row(
      children: [
        _RateColumn(
          icon: Icons.thermostat_auto,
          title: 'Ideal Rate',
          rate: patient.idealDoseRate,
        ),
        const SizedBox(width: 16),
        _RateColumn(
          icon: Icons.speed,
          title: 'Current Rate',
          rate: patient.currentDoseRate,
          color: _getDoseRateColor(),
          isEmphasized: true,
        ),
      ],
    );
  }

  Widget _buildAirBubbleWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        children: [
          Icon(Icons.air, color: Colors.red[400], size: 18),
          const SizedBox(width: 8),
          Text(
            'AIR BUBBLE DETECTED',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDoseRateColor() {
    final diff = (patient.currentDoseRate - patient.idealDoseRate).abs();
    if (diff > 5) return const Color(0xFFEF7C7C); // Soft Red
    if (diff > 2) return const Color(0xFFFFC94D); // Soft Amber
    return const Color(0xFF66BB6A); // Soft Green
  }
}

// Helper Widgets

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFC8E6C9) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: isActive ? const Color(0xFF388E3C) : Colors.grey[500],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RateColumn extends StatelessWidget {
  final IconData icon;
  final String title;
  final double rate;
  final Color? color;
  final bool isEmphasized;

  const _RateColumn({
    required this.icon,
    required this.title,
    required this.rate,
    this.color,
    this.isEmphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${rate.toStringAsFixed(1)} ml/h',
            style: TextStyle(
              fontSize: isEmphasized ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}