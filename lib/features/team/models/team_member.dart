class TeamMember {
  const TeamMember({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.designation,
    required this.location,
    required this.role,
    required this.permissions,
    required this.status,
    this.facebookUrl = '',
    this.instagramUrl = '',
  });

  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final String designation;
  final String location;
  final String role;
  final List<String> permissions;
  final String status;
  final String facebookUrl;
  final String instagramUrl;

  /// Phone number collected as the member's WhatsApp number.
  String get whatsappNumber => mobile;

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'];
    return TeamMember(
      id: '${json['id'] ?? ''}',
      fullName: '${json['fullName'] ?? ''}',
      mobile: '${json['whatsappNumber'] ?? json['mobile'] ?? ''}',
      email: '${json['email'] ?? ''}',
      designation: '${json['designation'] ?? ''}',
      location: '${json['location'] ?? ''}',
      role: '${json['role'] ?? ''}',
      permissions: [
        for (final item in rawPermissions is List ? rawPermissions : const [])
          '$item',
      ],
      status: '${json['status'] ?? 'pending'}',
      facebookUrl: '${json['facebookUrl'] ?? json['facebook_url'] ?? ''}',
      instagramUrl: '${json['instagramUrl'] ?? json['instagram_url'] ?? ''}',
    );
  }

  TeamMember copyWith({
    String? id,
    String? fullName,
    String? mobile,
    String? email,
    String? designation,
    String? location,
    String? role,
    List<String>? permissions,
    String? status,
    String? facebookUrl,
    String? instagramUrl,
  }) {
    return TeamMember(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      designation: designation ?? this.designation,
      location: location ?? this.location,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
    );
  }
}

class TeamStats {
  const TeamStats({
    required this.total,
    required this.active,
    required this.pending,
    required this.inactive,
  });

  final int total;
  final int active;
  final int pending;
  final int inactive;

  factory TeamStats.fromMembers(List<TeamMember> members) {
    return TeamStats(
      total: members.length,
      active: members.where((member) => member.status == 'active').length,
      pending: members.where((member) => member.status == 'pending').length,
      inactive: members.where((member) => member.status == 'inactive').length,
    );
  }

  static const empty = TeamStats(total: 0, active: 0, pending: 0, inactive: 0);
}
