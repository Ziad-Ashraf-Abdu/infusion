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
      await _flutterTts.awaitSpeakCompletion(true); // Ensure sequential speech

      // Available languages (for debugging)
      List<dynamic> langs = await _flutterTts.getLanguages;
      debugPrint("🌐 Available languages: $langs");

      // Try to set language
      if (await _flutterTts.isLanguageAvailable("en-US")) {
        await _flutterTts.setLanguage("en-US");
      } else {
        debugPrint("⚠️ en-US not available, using default TTS voice");
      }

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Handlers
      _flutterTts.setStartHandler(() {
        debugPrint("🗣️ Speaking started");
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint("✅ Speech completed");
        _isSpeaking = false;
        _processNextSpeech();
      });

      _flutterTts.setCancelHandler(() {
        debugPrint("⚠️ Speech canceled");
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

      // Test startup
      Future.delayed(const Duration(seconds: 1), () => _speak("Text to speech initialized"));
    } catch (e) {
      debugPrint("❌ Error initializing TTS: $e");
    }
  }

  Future<void> _speak(String text) async {
    if (!_ttsInitialized) {
      debugPrint("⚠️ TTS not ready, skipping: $text");
      return;
    }

    _speechQueue.add(text);
    debugPrint("🗯️ Added to queue: $text");

    if (!_isSpeaking) {
      _processNextSpeech();
    }
  }

  Future<void> _processNextSpeech() async {
    if (_speechQueue.isEmpty || _isSpeaking) return;

    final text = _speechQueue.removeAt(0);
    debugPrint("🎙️ Now speaking: $text");

    try {
      _isSpeaking = true;
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("❌ Speak error: $e");
      _isSpeaking = false;
      _processNextSpeech();
    }
  }

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
    final percentage = patient.currentLiquidLevel;
    String alarmType = '';

    if (percentage <= 2 && percentage > 0) {
      alarmType = 'critical';
      _triggerAlarm(patient, alarmType, _showEndOfInfusionAlert);
    } else if (percentage > 2 && percentage <= 10) {
      alarmType = 'low';
      _triggerAlarm(patient, alarmType, _showLowVolumeAlert);
    }
  }

  void _triggerAlarm(Patient patient, String alarmType, Function(Patient, double) alertFunction) {
    final alarmKey = '${patient.patientId}_$alarmType';
    if (_lastAlarmShown[alarmKey] != alarmType) {
      _lastAlarmShown[alarmKey] = alarmType;
      alertFunction(patient, patient.currentLiquidLevel);
    }
  }

  void _showAirBubbleAlert(Patient patient) {
    final msg = 'Air bubble detected for Patient number ${patient.patientId}, ${patient.drugName}. Immediate attention is required.';
    _speak(msg);

    if (!mounted) return;

    _showAlertDialog(
      title: 'Air Bubble Alert!',
      icon: Icons.warning_amber_rounded,
      color: Colors.redAccent,
      message: 'Air bubble detected for Patient #${patient.patientId} (${patient.drugName}). Immediate attention is required.',
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
              itemBuilder: (context, i) => PatientCard(patient: _patients[i]),
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
          Text(
            'No Patients Connected',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.displayLarge?.color,
            ),
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
    );
  }
}
