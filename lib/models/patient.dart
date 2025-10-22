class Patient {
  final String patientId;
  final String drugName;
  final double idealDoseRate;
  double currentDoseRate;
  double currentLiquidLevel;
  double? currentFlowRate; // Add this - current actual flow rate
  double? requiredFlowRate; // Add this - target flow rate (can use idealDoseRate or calculate from it)
  bool isActive;
  bool hasAirBubble;

  Patient({
    required this.patientId,
    required this.drugName,
    required this.idealDoseRate,
    required this.currentDoseRate,
    required this.currentLiquidLevel,
    this.currentFlowRate, // Add this
    this.requiredFlowRate, // Add this
    this.isActive = false,
    this.hasAirBubble = false,
  });

  factory Patient.fromQRCode(String qrData) {
    // Expected format: "patientId,drugName,idealDoseRate"
    final parts = qrData.split(',');
    return Patient(
      patientId: parts[0],
      drugName: parts[1],
      idealDoseRate: double.parse(parts[2]),
      currentDoseRate: 0.0,
      currentLiquidLevel: 100.0,
      requiredFlowRate: double.parse(parts[2]), // Set required flow rate to idealDoseRate
    );
  }

  void updateFromServer(Map<String, dynamic> serverData) {
    currentDoseRate = serverData['currentDoseRate'] ?? currentDoseRate;
    currentLiquidLevel = serverData['currentLiquidLevel'] ?? currentLiquidLevel;
    currentFlowRate = serverData['currentFlowRate'] ?? currentFlowRate; // Add this
    requiredFlowRate = serverData['requiredFlowRate'] ?? requiredFlowRate; // Add this
    isActive = serverData['isActive'] ?? isActive;
    hasAirBubble = serverData['hasAirBubble'] ?? hasAirBubble;
  }
}