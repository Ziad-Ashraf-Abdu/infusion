// services/server_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/patient.dart';

class ServerService {
  // *** Replace with your actual Hugging Face Space URL ***
  // It will look something like 'your-username-your-space-name.hf.space'
  final String _huggingFaceSpaceUrl = "https://huggingface.co/spaces/Zee1604/infusion";

  Timer? _pollingTimer;
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;

  final List<Patient> _patients = [];
  Function(Patient)? onPatientUpdate;

  // Starts polling for data and opens a WebSocket connection
  void startMonitoring(List<Patient> patients) {
    _patients.clear();
    _patients.addAll(patients);

    _stopPreviousConnections();

    // Start polling for patient data via HTTP GET requests
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      for (var patient in _patients) {
        _fetchPatientData(patient.patientId);
      }
    });

    // Connect to WebSocket for real-time flags
    _connectWebSocket();
  }

  // Fetches the latest data for a specific patient
  Future<void> _fetchPatientData(String patientId) async {
    try {
      final response = await http.get(Uri.https(_huggingFaceSpaceUrl, '/patient/$patientId'));

      if (response.statusCode == 200) {
        final serverData = json.decode(response.body);
        final patient = _patients.firstWhere((p) => p.patientId == patientId);

        // Store previous state for comparison
        final hadAirBubble = patient.hasAirBubble;
        
        // Update patient data from server
        patient.updateFromServer(serverData);

        // Trigger update callback
        onPatientUpdate?.call(patient);

        // Note: Air bubble detection removed as per requirements
        // Flow rate monitoring is now handled in HomeScreen through onPatientUpdate
      }
    } catch (e) {
      print("Error fetching data for patient $patientId: $e");
    }
  }

  // Connects to the WebSocket server to listen for commands
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://$_huggingFaceSpaceUrl/ws'),
      );

      _socketSubscription = _channel!.stream.listen((message) {
        print('Received command from server: $message');
        // Handle incoming commands if needed in the future
        
        // You could potentially parse flow rate data from WebSocket messages here
        // and update patients accordingly
        _handleWebSocketMessage(message);
      });
    } catch (e) {
      print("Error connecting to WebSocket: $e");
    }
  }

  // Handle incoming WebSocket messages
  void _handleWebSocketMessage(String message) {
    try {
      final data = json.decode(message);
      
      // Example WebSocket message format for flow rate data:
      // {
      //   "type": "flow_rate_update",
      //   "patientId": "123",
      //   "currentFlowRate": 45.2,
      //   "requiredFlowRate": 50.0
      // }
      
      if (data['type'] == 'flow_rate_update') {
        final patientId = data['patientId'];
        final patient = _patients.firstWhere(
          (p) => p.patientId == patientId,
          orElse: () => Patient(
            patientId: patientId,
            drugName: 'Unknown',
            idealDoseRate: 0.0,
            currentDoseRate: 0.0,
            currentLiquidLevel: 0.0,
          ),
        );
        
        // Update flow rate data
        if (data['currentFlowRate'] != null) {
          // This would require adding a setter or making currentFlowRate non-final
          // For now, we rely on HTTP polling for flow rate data
        }
        
        onPatientUpdate?.call(patient);
      }
    } catch (e) {
      print("Error handling WebSocket message: $e");
    }
  }

  // Sends a flag/command to the server via WebSocket
  void sendCommand(String command) {
    if (_channel != null) {
      _channel!.sink.add(command);
      print('Sent command: $command');
    }
  }

  // Send flow rate calibration command
  void sendFlowRateCalibration(String patientId, double targetFlowRate) {
    final command = json.encode({
      'type': 'calibrate_flow_rate',
      'patientId': patientId,
      'targetFlowRate': targetFlowRate,
    });
    sendCommand(command);
  }

  void _stopPreviousConnections() {
    _pollingTimer?.cancel();
    _socketSubscription?.cancel();
    _channel?.sink.close();
  }

  void dispose() {
    _stopPreviousConnections();
  }
}