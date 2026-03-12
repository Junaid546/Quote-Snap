import '../../../domain/entities/quote_entity.dart';

class QuoteFirestoreModel {
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
  final int createdAt;
  final int updatedAt;
  final List<QuoteItemFirestoreModel> items;

  QuoteFirestoreModel({
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
    required this.items,
  });

  factory QuoteFirestoreModel.fromJson(Map<String, dynamic> json) {
    return QuoteFirestoreModel(
      id: json['id'],
      quoteNumber: json['quoteNumber'],
      clientId: json['clientId'],
      clientName: json['clientName'],
      jobType: json['jobType'],
      jobAddress: json['jobAddress'],
      photosPaths: List<String>.from(json['photosPaths'] ?? []),
      voiceNotePath: json['voiceNotePath'],
      notes: json['notes'],
      laborHours: (json['laborHours'] as num).toDouble(),
      laborRate: (json['laborRate'] as num).toDouble(),
      taxRate: (json['taxRate'] as num).toDouble(),
      applyTax: json['applyTax'],
      status: json['status'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      items:
          (json['items'] as List?)
              ?.map((i) => QuoteItemFirestoreModel.fromJson(i))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quoteNumber': quoteNumber,
      'clientId': clientId,
      'clientName': clientName,
      'jobType': jobType,
      'jobAddress': jobAddress,
      'photosPaths': photosPaths,
      'voiceNotePath': voiceNotePath,
      'notes': notes,
      'laborHours': laborHours,
      'laborRate': laborRate,
      'taxRate': taxRate,
      'applyTax': applyTax,
      'status': status,
      'totalAmount': totalAmount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  factory QuoteFirestoreModel.fromEntity(QuoteEntity entity) {
    return QuoteFirestoreModel(
      id: entity.id,
      quoteNumber: entity.quoteNumber,
      clientId: entity.clientId,
      clientName: entity.clientName,
      jobType: entity.jobType,
      jobAddress: entity.jobAddress,
      photosPaths: entity.photosPaths,
      voiceNotePath: entity.voiceNotePath,
      notes: entity.notes,
      laborHours: entity.laborHours,
      laborRate: entity.laborRate,
      taxRate: entity.taxRate,
      applyTax: entity.applyTax,
      status: entity.status,
      totalAmount: entity.totalAmount,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
      items: entity.items
          .map((i) => QuoteItemFirestoreModel.fromEntity(i))
          .toList(),
    );
  }

  QuoteEntity toEntity() {
    return QuoteEntity(
      id: id,
      quoteNumber: quoteNumber,
      clientId: clientId,
      clientName: clientName,
      jobType: jobType,
      jobAddress: jobAddress,
      photosPaths: photosPaths,
      voiceNotePath: voiceNotePath,
      notes: notes,
      laborHours: laborHours,
      laborRate: laborRate,
      taxRate: taxRate,
      applyTax: applyTax,
      status: status,
      totalAmount: totalAmount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      isSynced: true, // From Firestore implies it is synced
      items: items.map((i) => i.toEntity()).toList(),
    );
  }
}

class QuoteItemFirestoreModel {
  final String id;
  final String quoteId;
  final String name;
  final double unitPrice;
  final int quantity;
  final bool isChecked;

  QuoteItemFirestoreModel({
    required this.id,
    required this.quoteId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.isChecked,
  });

  factory QuoteItemFirestoreModel.fromJson(Map<String, dynamic> json) {
    return QuoteItemFirestoreModel(
      id: json['id'],
      quoteId: json['quoteId'],
      name: json['name'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'],
      isChecked: json['isChecked'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quoteId': quoteId,
      'name': name,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'isChecked': isChecked,
    };
  }

  factory QuoteItemFirestoreModel.fromEntity(QuoteItemEntity entity) {
    return QuoteItemFirestoreModel(
      id: entity.id,
      quoteId: entity.quoteId,
      name: entity.name,
      unitPrice: entity.unitPrice,
      quantity: entity.quantity,
      isChecked: entity.isChecked,
    );
  }

  QuoteItemEntity toEntity() {
    return QuoteItemEntity(
      id: id,
      quoteId: quoteId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity,
      isChecked: isChecked,
    );
  }
}
