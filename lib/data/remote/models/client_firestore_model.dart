import '../../../domain/entities/client_entity.dart';

class ClientFirestoreModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int totalQuotes;
  final double totalValue;
  final int createdAt;

  ClientFirestoreModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.totalQuotes,
    required this.totalValue,
    required this.createdAt,
  });

  factory ClientFirestoreModel.fromJson(Map<String, dynamic> json) {
    return ClientFirestoreModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      totalQuotes: json['totalQuotes'] ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'totalQuotes': totalQuotes,
      'totalValue': totalValue,
      'createdAt': createdAt,
    };
  }

  factory ClientFirestoreModel.fromEntity(ClientEntity entity) {
    return ClientFirestoreModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      address: entity.address,
      totalQuotes: entity.totalQuotes,
      totalValue: entity.totalValue,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
    );
  }

  ClientEntity toEntity() {
    return ClientEntity(
      id: id,
      name: name,
      phone: phone,
      email: email,
      address: address,
      totalQuotes: totalQuotes,
      totalValue: totalValue,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    );
  }
}
