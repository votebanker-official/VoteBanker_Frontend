const volunteerRoles = <String>[
  'General Volunteer',
  'Field Volunteer',
  'Team Coordinator',
  'Event Volunteer',
  'Content & Social Media Volunteer',
  'Data Entry Volunteer',
  'Technical Support Volunteer',
];

const volunteerStatuses = <String>['active', 'inactive', 'pending'];
const applicationStatuses = <String>['pending', 'approved', 'rejected'];
const taskPriorities = <String>['low', 'medium', 'high'];
const taskStatuses = <String>['pending', 'in_progress', 'completed'];

class VolunteerStats {
  const VolunteerStats({
    required this.totalVolunteers,
    required this.activeVolunteers,
    required this.pendingApplications,
    required this.unassignedVolunteers,
  });

  final int totalVolunteers;
  final int activeVolunteers;
  final int pendingApplications;
  final int unassignedVolunteers;

  factory VolunteerStats.fromJson(Map<String, dynamic> json) {
    return VolunteerStats(
      totalVolunteers: _int(json['totalVolunteers']),
      activeVolunteers: _int(json['activeVolunteers']),
      pendingApplications: _int(json['pendingApplications']),
      unassignedVolunteers: _int(json['unassignedVolunteers']),
    );
  }

  static const empty = VolunteerStats(
    totalVolunteers: 0,
    activeVolunteers: 0,
    pendingApplications: 0,
    unassignedVolunteers: 0,
  );
}

class VolunteerTeam {
  const VolunteerTeam({
    required this.id,
    required this.name,
    this.description,
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final int memberCount;

  factory VolunteerTeam.fromJson(Map<String, dynamic> json) {
    return VolunteerTeam(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      description: json['description'] as String?,
      memberCount: _int(json['memberCount']),
    );
  }
}

class VolunteerRecord {
  const VolunteerRecord({
    required this.id,
    required this.volunteerCode,
    required this.fullName,
    required this.mobile,
    this.email,
    required this.role,
    this.teamId,
    this.teamName,
    this.location,
    this.photoUrl,
    this.skills,
    this.availability,
    required this.status,
    this.notes,
    this.registeredAt,
    this.updatedAt,
  });

  final String id;
  final String volunteerCode;
  final String fullName;
  final String mobile;
  final String? email;
  final String role;
  final String? teamId;
  final String? teamName;
  final String? location;
  final String? photoUrl;
  final String? skills;
  final String? availability;
  final String status;
  final String? notes;
  final String? registeredAt;
  final String? updatedAt;

  factory VolunteerRecord.fromJson(Map<String, dynamic> json) {
    return VolunteerRecord(
      id: '${json['id']}',
      volunteerCode: '${json['volunteerCode'] ?? ''}',
      fullName: '${json['fullName'] ?? ''}',
      mobile: '${json['mobile'] ?? ''}',
      email: json['email'] as String?,
      role: '${json['role'] ?? ''}',
      teamId: json['teamId'] as String?,
      teamName: json['teamName'] as String?,
      location: json['location'] as String?,
      photoUrl: json['photoUrl'] as String?,
      skills: json['skills'] as String?,
      availability: json['availability'] as String?,
      status: '${json['status'] ?? 'active'}',
      notes: json['notes'] as String?,
      registeredAt: json['registeredAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'mobile': mobile,
        'email': email,
        'role': role,
        'teamId': teamId,
        'location': location,
        'photoUrl': photoUrl,
        'skills': skills,
        'availability': availability,
        'status': status,
        'notes': notes,
      };

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

class VolunteerTask {
  const VolunteerTask({
    required this.id,
    required this.title,
    this.description,
    this.volunteerId,
    this.volunteerName,
    this.teamId,
    this.teamName,
    this.dueDate,
    required this.priority,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? volunteerId;
  final String? volunteerName;
  final String? teamId;
  final String? teamName;
  final String? dueDate;
  final String priority;
  final String status;
  final String? createdAt;

  factory VolunteerTask.fromJson(Map<String, dynamic> json) {
    return VolunteerTask(
      id: '${json['id']}',
      title: '${json['title'] ?? ''}',
      description: json['description'] as String?,
      volunteerId: json['volunteerId'] as String?,
      volunteerName: json['volunteerName'] as String?,
      teamId: json['teamId'] as String?,
      teamName: json['teamName'] as String?,
      dueDate: json['dueDate'] as String?,
      priority: '${json['priority'] ?? 'medium'}',
      status: '${json['status'] ?? 'pending'}',
      createdAt: json['createdAt'] as String?,
    );
  }
}

class VolunteerApplication {
  const VolunteerApplication({
    required this.id,
    required this.fullName,
    required this.mobile,
    this.email,
    required this.role,
    this.skills,
    this.availability,
    this.notes,
    required this.status,
    this.volunteerId,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String mobile;
  final String? email;
  final String role;
  final String? skills;
  final String? availability;
  final String? notes;
  final String status;
  final String? volunteerId;
  final String? createdAt;

  factory VolunteerApplication.fromJson(Map<String, dynamic> json) {
    return VolunteerApplication(
      id: '${json['id']}',
      fullName: '${json['fullName'] ?? ''}',
      mobile: '${json['mobile'] ?? ''}',
      email: json['email'] as String?,
      role: '${json['role'] ?? ''}',
      skills: json['skills'] as String?,
      availability: json['availability'] as String?,
      notes: json['notes'] as String?,
      status: '${json['status'] ?? 'pending'}',
      volunteerId: json['volunteerId'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class VolunteerActivity {
  const VolunteerActivity({
    required this.id,
    required this.action,
    this.detail,
    this.createdAt,
  });

  final String id;
  final String action;
  final String? detail;
  final String? createdAt;

  factory VolunteerActivity.fromJson(Map<String, dynamic> json) {
    return VolunteerActivity(
      id: '${json['id']}',
      action: '${json['action'] ?? ''}',
      detail: json['detail'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class VolunteerOverview {
  const VolunteerOverview({
    required this.stats,
    required this.recentVolunteers,
    required this.recentActivity,
    required this.teams,
  });

  final VolunteerStats stats;
  final List<VolunteerRecord> recentVolunteers;
  final List<VolunteerActivity> recentActivity;
  final List<VolunteerTeam> teams;

  factory VolunteerOverview.fromJson(Map<String, dynamic> json) {
    return VolunteerOverview(
      stats: VolunteerStats.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      recentVolunteers: _list(json['recentVolunteers'], VolunteerRecord.fromJson),
      recentActivity: _list(json['recentActivity'], VolunteerActivity.fromJson),
      teams: _list(json['teams'], VolunteerTeam.fromJson),
    );
  }
}

class VolunteerPage {
  const VolunteerPage({
    required this.volunteers,
    required this.page,
    required this.pageSize,
    required this.total,
    this.locations = const [],
  });

  final List<VolunteerRecord> volunteers;
  final int page;
  final int pageSize;
  final int total;
  final List<String> locations;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) map) {
  if (value is! List) return const [];
  return [
    for (final row in value)
      if (row is Map<String, dynamic>) map(row),
  ];
}
