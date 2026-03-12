class ClientEntity {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int totalQuotes;
  final double totalValue;
  final DateTime createdAt;

  const ClientEntity({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.totalQuotes,
    required this.totalValue,
    required this.createdAt,
  });
}
