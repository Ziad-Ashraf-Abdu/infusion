import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/patient.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      setState(() {
        _scanned = true;
      });

      try {
        final patient = Patient.fromQRCode(code);
        Navigator.pop(context, patient);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid QR Code format: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _scanned = false;
        });
      }
    }
  }

  void _toggleTorch() {
    setState(() {
      _torchOn = !_torchOn;
    });
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Patient QR Code'),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Error',
                      style: TextStyle(color: Colors.red[700], fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        error.errorDetails?.message ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _controller.start(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
          ),
          // Scanning overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Position QR code within frame',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          // Simulate scan buttons for testing different scenarios
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _simulateScan(50.0),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Normal (50%)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _simulateScan(8.0),
                    icon: const Icon(Icons.water_drop_outlined),
                    label: const Text('Low Volume (8%)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _simulateScan(1.5),
                    icon: const Icon(Icons.error_outline),
                    label: const Text('Critical (1.5%)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateScan(double liquidLevel) {
    if (_scanned) return;

    setState(() {
      _scanned = true;
    });

    // Simulate QR code data: "patientId,drugName,idealDoseRate"
    final qrData = 'PT${DateTime.now().millisecondsSinceEpoch % 10000},Dopamine,50.0';
    try {
      final patient = Patient.fromQRCode(qrData);
      // Create a copy with the specific liquid level for testing
      final testPatient = Patient(
        patientId: patient.patientId,
        drugName: patient.drugName,
        idealDoseRate: patient.idealDoseRate,
        currentDoseRate: patient.currentDoseRate,
        currentLiquidLevel: liquidLevel,
      );
      Navigator.pop(context, testPatient);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating patient: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _scanned = false;
      });
    }
  }
}