class Patient {
  final String patientId;
  final String drugName;
  final double idealDoseRate;
  double currentDoseRate;
  double currentLiquidLevel;
  bool isActive;
  bool hasAirBubble;

  Patient({
    required this.patientId,
    required this.drugName,
    required this.idealDoseRate,
    required this.currentDoseRate,
    required this.currentLiquidLevel,
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
    );
  }

  void updateFromServer(Map<String, dynamic> serverData) {
    currentDoseRate = serverData['currentDoseRate'] ?? currentDoseRate;
    currentLiquidLevel = serverData['currentLiquidLevel'] ?? currentLiquidLevel;
    isActive = serverData['isActive'] ?? isActive;
    hasAirBubble = serverData['hasAirBubble'] ?? hasAirBubble;
  }
}