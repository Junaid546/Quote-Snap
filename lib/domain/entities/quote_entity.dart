class QuoteItemEntity {
  final String id;
  final String quoteId;
  final String name;
  final double unitPrice;
  final int quantity;
  final bool isChecked;

  const QuoteItemEntity({
    required this.id,
    required this.quoteId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.isChecked,
  });
}

class QuoteEntity {
  final String id;
  final int quoteNumber;
  final String clientId;
  final String clientName;
  final String jobType;
  final String jobAddress;
  final List<String> photosPaths;
  final String? voiceNotePath;
  final String notes;
  final double laborHours;
  final double laborRate;
  final double taxRate;
  final bool applyTax;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final List<QuoteItemEntity> items;

  const QuoteEntity({
    required this.id,
    required this.quoteNumber,
    required this.clientId,
    required this.clientName,
    required this.jobType,
    required this.jobAddress,
    required this.photosPaths,
    this.voiceNotePath,
    required this.notes,
    required this.laborHours,
    required this.laborRate,
    required this.taxRate,
    required this.applyTax,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.items = const [],
  });
}
