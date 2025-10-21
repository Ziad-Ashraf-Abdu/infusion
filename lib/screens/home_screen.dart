// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/patient.dart';
import '../services/server_service.dart';
import '../widgets/patient_card.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final Function(ThemeMode) onThemeChanged;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Patient> _patients = [];
  final ServerService _serverService = ServerService();
  final FlutterTts _flutterTts = FlutterTts();

  final Map<String, String> _lastAlarmShown = {}; // Track last alarm per patient
  final List<String> _speechQueue = [];

  bool _isSpeaking = false;
  bool _ttsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _setupServerListeners();
  }

  // --- TTS and Alert Logic (Unchanged) ---
  Future<void> _initializeTts() async {
    // ... TTS initialization logic ...
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      if (await _flutterTts.isLanguageAvailable("en-US")) {
        await _flutterTts.setLanguage("en-US");
      }
      await _flutterTts.setSpeechRate(0.5);
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _processNextSpeech();
      });
      _flutterTts.setErrorHandler((msg) {
        debugPrint("❌ TTS error: $msg");
        _isSpeaking = false;
        _processNextSpeech();
      });
      _ttsInitialized = true;
      debugPrint("✅ TTS initialized successfully");
    } catch (e) {
      debugPrint("❌ Error initializing TTS: $e");
    }
  }

  Future<void> _speak(String text) async {
    if (!_ttsInitialized) return;
    _speechQueue.add(text);
    if (!_isSpeaking) _processNextSpeech();
  }

  Future<void> _processNextSpeech() async {
    if (_speechQueue.isEmpty || _isSpeaking) return;
    final text = _speechQueue.removeAt(0);
    _isSpeaking = true;
    await _flutterTts.speak(text);
  }
  // ... Alert functions like _showAirBubbleAlert remain the same ...

  // --- Server Listeners and Data Handling (Unchanged) ---
  void _setupServerListeners() {
    _serverService.onPatientUpdate = (patient) {
      if (mounted) {
        setState(() {});
        _checkLiquidLevel(patient);
      }
    };
    _serverService.onAirBubbleDetected = (patient) {
      _showAirBubbleAlert(patient);
    };
  }

  void _checkLiquidLevel(Patient patient) {
    // ... Liquid level check logic ...
  }

  void _triggerAlarm(Patient patient, String alarmType, Function(Patient, double) alertFunction) {
    // ... Alarm trigger logic ...
  }

  // --- New Function to Handle Pump Activation ---
  /// This function is called by the PatientCard when the user taps the status chip.
  void _handleToggleActive(Patient patient, bool newStatus) {
    if (newStatus == true) {
      // User wants to ACTIVATE the pump.
      // We'll use a safe, default PWM speed (e.g., 150) and a default volume.
      // The idealDoseRate from the QR code is for display; Arduino needs a PWM value (0-255).
      const int speed = 150;
      const int volume = 120; // Default volume in mL

      // Construct the command Arduino expects: START:patientId:speed:volume
      final command = 'START:${patient.patientId}:$speed:$volume';
      debugPrint('Sending command: $command');
      _serverService.sendCommand(command);
    } else {
      // User wants to DEACTIVATE the pump.
      const command = 'STOP';
      debugPrint('Sending command: $command');
      _serverService.sendCommand(command);
    }
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
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _checkLiquidLevel(result);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _serverService.dispose();
    super.dispose();
  }

  // --- Build Method (Updated) ---
  @override
  Widget build(BuildContext context) {
    final isLight = widget.themeMode == ThemeMode.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Infusion Monitor'),
        actions: [
          IconButton(
            icon: Icon(isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
            onPressed: () => widget.onThemeChanged(isLight ? ThemeMode.dark : ThemeMode.light),
          ),
        ],
      ),
      body: _patients.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
        itemCount: _patients.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // *** THIS IS THE UPDATED PART ***
        itemBuilder: (context, i) {
          final patient = _patients[i];
          return PatientCard(
            patient: patient,
            // Pass the handler function to the PatientCard.
            onToggleActive: (newStatus) {
              _handleToggleActive(patient, newStatus);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPatient,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan Patient'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // ... Empty state widget (unchanged) ...
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_information_outlined,
              size: 100, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text('No Patients Connected', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to scan a patient\'s QR code',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- Alert Dialog (for brevity, showing just the signature) ---
  void _showAirBubbleAlert(Patient patient) { /* ... */ }
  void _showLowVolumeAlert(Patient patient, double percentage) { /* ... */ }
  void _showEndOfInfusionAlert(Patient patient, double percentage) { /* ... */ }
  void _showAlertDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) { /* ... */ }
}