class EffectivePermissionEntity {
  const EffectivePermissionEntity({
    required this.userId,
    required this.role,
    required this.actions,
    required this.resources,
    required this.fieldTypes,
    required this.canManagePermissions,
    required this.canManageScoring,
    required this.canManagePublicProtection,
    this.organizationId,
  });

  final String userId;
  final String? organizationId;
  final String role;
  final List<String> actions;
  final List<String> resources;
  final List<String> fieldTypes;
  final bool canManagePermissions;
  final bool canManageScoring;
  final bool canManagePublicProtection;
}
