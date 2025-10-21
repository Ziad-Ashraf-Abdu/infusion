// services/server_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/patient.dart'; // Make sure this path is correct

class ServerService {
  // Use the host name for both HTTP and WebSocket
  final String _huggingFaceHost = "Zee1604-infusion.hf.space";

  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;

  final List<Patient> _patients = [];
  Function(Patient)? onPatientUpdate;
  Function(Patient)? onAirBubbleDetected;

  /// Starts monitoring by fetching initial data and then listening on WebSocket.
  void startMonitoring(List<Patient> patients) {
    _patients.clear();
    _patients.addAll(patients);

    _stopPreviousConnections();

    // 1. Fetch the *initial* data for each patient via HTTP.
    for (var patient in _patients) {
      _fetchInitialPatientData(patient.patientId);
    }

    // 2. Connect to WebSocket for all *subsequent* real-time updates.
    _connectWebSocket();
  }

  /// Fetches the initial state of a patient when monitoring starts.
  Future<void> _fetchInitialPatientData(String patientId) async {
    try {
      final uri = Uri.https(_huggingFaceHost, '/patient/$patientId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final serverData = json.decode(response.body);
        _updatePatientData(patientId, serverData);
        print("✅ Fetched initial data for $patientId");
      } else {
        print("⚠️ Could not fetch initial data for $patientId: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching initial data for patient $patientId: $e");
    }
  }

  /// Unified function to update patient state and trigger UI callbacks.
  void _updatePatientData(String patientId, Map<String, dynamic> serverData) {
    try {
      final patient = _patients.firstWhere((p) => p.patientId == patientId);
      final hadAirBubble = patient.hasAirBubble;

      patient.updateFromServer(serverData);
      onPatientUpdate?.call(patient); // Notify UI to rebuild

      if (patient.hasAirBubble && !hadAirBubble) {
        onAirBubbleDetected?.call(patient); // Trigger specific alert
      }
    } catch (e) {
      print("⚠️ Received data for an unknown or unmonitored patient: $patientId");
    }
  }

  /// Connects to the WebSocket to listen for real-time data updates.
  void _connectWebSocket() {
    try {
      final uri = Uri.parse('wss://$_huggingFaceHost/ws');
      _channel = WebSocketChannel.connect(uri);
      print("✅ WebSocket connecting...");

      _socketSubscription = _channel!.stream.listen((message) {
        print('⬅️ Received data update from server: $message');
        final serverData = json.decode(message) as Map<String, dynamic>;

        // For now, we assume any update is for the first patient.
        // For a multi-patient app, the server would need to include the
        // patientId in the broadcast message.
        if (_patients.isNotEmpty) {
          _updatePatientData(_patients.first.patientId, serverData);
        }

      }, onError: (error) {
        print("❌ WebSocket error: $error");
      }, onDone: () {
        print("🔌 WebSocket connection closed. Attempting to reconnect...");
        // Simple reconnection logic
        Future.delayed(const Duration(seconds: 5), () => _connectWebSocket());
      });
    } catch (e) {
      print("❌ Error connecting to WebSocket: $e");
    }
  }

  /// Sends a command to the server via WebSocket.
  void sendCommand(String command) {
    if (_channel != null) {
      // Structure the message as a JSON object
      final message = json.encode({
        "type": "command",
        "payload": command
      });
      _channel!.sink.add(message);
      print('➡️ Sent command: $command');
    } else {
      print("⚠️ Cannot send command, WebSocket is not connected.");
    }
  }

  void _stopPreviousConnections() {
    _socketSubscription?.cancel();
    _channel?.sink.close();
  }

  void dispose() {
    _stopPreviousConnections();
  }
}