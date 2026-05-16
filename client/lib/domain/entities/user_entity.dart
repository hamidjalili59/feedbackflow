class UserEntity {
  const UserEntity({
    required this.id,
    required this.phone,
    this.email,
    required this.displayName,
    required this.role,
    required this.status,
    this.organizationId,
  });

  final String id;
  final String? organizationId;
  final String phone;
  final String? email;
  final String displayName;
  final String role;
  final String status;
}
