// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/server_service.dart';
import '../widgets/patient_card.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final Function(ThemeMode) onThemeChanged;

  const HomeScreen({
    Key? key,
    required this.themeMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Patient> _patients = [];
  final ServerService _serverService = ServerService();

  // (All the other functions like initState, _setupServerListeners, etc. remain the same)
  @override
  void initState() {
    super.initState();
    _setupServerListeners();
  }

  void _setupServerListeners() {
    _serverService.onPatientUpdate = (patient) {
      if (mounted) {
        setState(() {});
      }
    };

    _serverService.onAirBubbleDetected = (patient) {
      _showAirBubbleAlert(patient);
    };
  }

  void _showAirBubbleAlert(Patient patient) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 12),
            Text('Air Bubble Alert!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Air bubble detected for Patient #${patient.patientId} (${patient.drugName}). Immediate attention is required.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ACKNOWLEDGE'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null && result is Patient) {
      setState(() {
        _patients.add(result);
      });
      _serverService.startMonitoring(_patients);
    }
  }

  @override
  void dispose() {
    _serverService.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    bool isLightMode = widget.themeMode == ThemeMode.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Infusion Monitor'),
        actions: [
          IconButton(
            icon: Icon(
              isLightMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            ),
            onPressed: () {
              widget.onThemeChanged(
                isLightMode ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
        ],
      ),
      body: _patients.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Patients Connected',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.displayLarge?.color),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to scan a patient\'s QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _patients.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          return PatientCard(patient: _patients[index]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPatient,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan Patient'),
      ),
    );
  }
}