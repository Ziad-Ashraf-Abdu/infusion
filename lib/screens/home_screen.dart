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

  Future<void> _initializeTts() async {
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

  void _setupServerListeners() {
    _serverService.onPatientUpdate = (patient) {
      if (mounted) {
        setState(() {});
        _checkLiquidLevel(patient);
        _checkFlowRate(patient);
      }
    };
  }

  void _checkLiquidLevel(Patient patient) {
    final percentage = patient.currentLiquidLevel;
    String alarmType = '';

    if (percentage <= 2 && percentage > 0) {
      alarmType = 'critical';
      _triggerAlarm(patient, alarmType, () => _showEndOfInfusionAlert(patient, percentage));
    } else if (percentage > 2 && percentage <= 10) {
      alarmType = 'low';
      _triggerAlarm(patient, alarmType, () => _showLowVolumeAlert(patient, percentage));
    }
  }

  void _checkFlowRate(Patient patient) {
    final currentFlowRate = patient.currentFlowRate;
    final requiredFlowRate = patient.requiredFlowRate;
    
    // Check if flow rate data is available
    if (currentFlowRate == null || requiredFlowRate == null) return;
    
    // Calculate the acceptable range (within 20% of required flow rate)
    final lowerThreshold = requiredFlowRate * 0.8;  // 20% less
    final upperThreshold = requiredFlowRate * 1.2;  // 20% more
    
    String alarmType = '';
    
    if (currentFlowRate < lowerThreshold) {
      alarmType = 'flow_low';
      _triggerAlarm(patient, alarmType, () => _showLowFlowRateAlert(patient));
    } else if (currentFlowRate > upperThreshold) {
      alarmType = 'flow_high';
      _triggerAlarm(patient, alarmType, () => _showHighFlowRateAlert(patient));
    }
  }

  void _triggerAlarm(Patient patient, String alarmType, Function() alertFunction) {
    final alarmKey = '${patient.patientId}_$alarmType';
    if (_lastAlarmShown[alarmKey] != alarmType) {
      _lastAlarmShown[alarmKey] = alarmType;
      alertFunction(); // Call the parameterless function
    }
  }

  void _showLowFlowRateAlert(Patient patient) {
    final currentFlowRate = patient.currentFlowRate ?? 0;
    final requiredFlowRate = patient.requiredFlowRate ?? 0;
    final deviation = ((requiredFlowRate - currentFlowRate) / requiredFlowRate * 100).abs();
    
    final msg = 'Low flow rate alert for Patient number ${patient.patientId}. Current flow rate is ${deviation.toStringAsFixed(1)} percent below required rate. Please check for occlusions.';
    _speak(msg);

    if (!mounted) return;

    _showAlertDialog(
      title: 'Low Flow Rate Alert!',
      icon: Icons.trending_down_rounded,
      color: Colors.orangeAccent,
      message: 'Patient #${patient.patientId} (${patient.drugName}) has low flow rate.\n\n'
          'Required: ${requiredFlowRate.toStringAsFixed(2)} mL/hr\n'
          'Current: ${currentFlowRate.toStringAsFixed(2)} mL/hr\n'
          'Deviation: ${deviation.toStringAsFixed(1)}% below required\n\n'
          'Please check for line occlusions, kinks, or pump issues.',
    );
  }

  void _showHighFlowRateAlert(Patient patient) {
    final currentFlowRate = patient.currentFlowRate ?? 0;
    final requiredFlowRate = patient.requiredFlowRate ?? 0;
    final deviation = ((currentFlowRate - requiredFlowRate) / requiredFlowRate * 100).abs();
    
    final msg = 'High flow rate alert for Patient number ${patient.patientId}. Current flow rate is ${deviation.toStringAsFixed(1)} percent above required rate. Please check pump calibration.';
    _speak(msg);

    if (!mounted) return;

    _showAlertDialog(
      title: 'High Flow Rate Alert!',
      icon: Icons.trending_up_rounded,
      color: Colors.redAccent,
      message: 'Patient #${patient.patientId} (${patient.drugName}) has high flow rate.\n\n'
          'Required: ${requiredFlowRate.toStringAsFixed(2)} mL/hr\n'
          'Current: ${currentFlowRate.toStringAsFixed(2)} mL/hr\n'
          'Deviation: ${deviation.toStringAsFixed(1)}% above required\n\n'
          'Please check pump calibration and patient safety.',
    );
  }

  void _showLowVolumeAlert(Patient patient, double percentage) {
    final msg = 'Low volume alert for Patient number ${patient.patientId}. ${percentage.toStringAsFixed(1)} percent remaining. Please prepare a new syringe or bag.';
    _speak(msg);

    if (!mounted) return;

    _showAlertDialog(
      title: 'Low Volume Alert',
      icon: Icons.water_drop_outlined,
      color: Colors.orangeAccent,
      message: 'Patient #${patient.patientId} (${patient.drugName}) has ${percentage.toStringAsFixed(1)}% remaining.\n\nPlease prepare a new syringe or bag.',
    );
  }

  void _showEndOfInfusionAlert(Patient patient, double percentage) {
    final msg = 'Critical alert! End of infusion for Patient number ${patient.patientId}. Only ${percentage.toStringAsFixed(1)} percent remaining. Immediate intervention required.';
    _speak(msg);

    if (!mounted) return;

    _showAlertDialog(
      title: 'End of Infusion!',
      icon: Icons.error_outline_rounded,
      color: Colors.red,
      message: 'Patient #${patient.patientId} (${patient.drugName}) is critically low at ${percentage.toStringAsFixed(1)}% remaining.\n\nAir may enter the line. Immediate intervention required!',
    );
  }

  void _showAlertDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ACKNOWLEDGE', style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  // This function is called by the PatientCard when the user taps the status chip.
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
      if (mounted) {
        _checkLiquidLevel(result);
        _checkFlowRate(result);
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _serverService.dispose();
    super.dispose();
  }

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
}