class UserProfileEntity {
  final String id;
  final String businessName;
  final String ownerName;
  final String email;
  final String phone;
  final String licenseNumber;
  final String? logoPath;
  final double defaultHourlyRate;
  final double defaultTaxRate;
  final String subscriptionPlan;
  final String? subscriptionRenewal;

  const UserProfileEntity({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    this.logoPath,
    required this.defaultHourlyRate,
    required this.defaultTaxRate,
    required this.subscriptionPlan,
    this.subscriptionRenewal,
  });
}
