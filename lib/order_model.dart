class Order {
  final String customerName;
  final String dentalTechnicianName;
  final String toothColor;
  final List<String> selectedTeeth;
  final String orderDetails;
  final List<String> orderFiles; // Assuming file paths or names

  Order({
    required this.customerName,
    required this.dentalTechnicianName,
    required this.toothColor,
    required this.selectedTeeth,
    required this.orderDetails,
    required this.orderFiles,
  });

  // You can add methods for serialization/deserialization here if needed
}