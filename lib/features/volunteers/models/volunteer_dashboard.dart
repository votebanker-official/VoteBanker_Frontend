import 'volunteer_models.dart';

/// Row shown in the Volunteers Management table.
///
/// Kept separate from [VolunteerRecord] so the dashboard can run on the
/// screenshot sample set, then later map records from the existing API.
class DashboardVolunteer {
  const DashboardVolunteer({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.skills,
    this.availability,
    this.email,
    this.phone,
    this.notes,
    this.role = 'General Volunteer',
  });

  final String id;
  final String name;
  final String location;
  final String status;
  final List<String> skills;
  final String? availability;
  final String? email;
  final String? phone;
  final String? notes;
  final String role;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  DashboardVolunteer copyWith({
    String? name,
    String? location,
    String? status,
    List<String>? skills,
    Object? availability = _keep,
    Object? email = _keep,
    Object? phone = _keep,
    Object? notes = _keep,
    String? role,
  }) {
    return DashboardVolunteer(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      status: status ?? this.status,
      skills: skills ?? this.skills,
      availability: availability == _keep ? this.availability : availability as String?,
      email: email == _keep ? this.email : email as String?,
      phone: phone == _keep ? this.phone : phone as String?,
      notes: notes == _keep ? this.notes : notes as String?,
      role: role ?? this.role,
    );
  }
}

const _keep = Object();

const dashboardStatuses = ['Active', 'Onboarding', 'Inactive'];
const dashboardAvailabilities = ['Regular', 'Ad Hoc'];

/// Maps an existing API volunteer into the dashboard table.
DashboardVolunteer dashboardVolunteerFromRecord(VolunteerRecord record) {
  return DashboardVolunteer(
    id: record.id,
    name: record.fullName,
    location: (record.location ?? '').trim().isEmpty ? '—' : record.location!.trim(),
    status: volunteerStatusLabel(record.status),
    skills: splitVolunteerSkills(record.skills),
    availability: _clean(record.availability),
    email: _clean(record.email),
    phone: _clean(record.mobile),
    notes: _clean(record.notes),
    role: record.role.trim().isEmpty ? 'General Volunteer' : record.role.trim(),
  );
}

List<String> splitVolunteerSkills(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return const [];
  return [
    for (final part in text.split(RegExp(r'[,;|]')))
      if (part.trim().isNotEmpty) part.trim(),
  ];
}

String? _clean(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}

String volunteerStatusLabel(String status) {
  return switch (status.trim().toLowerCase()) {
    'active' => 'Active',
    'pending' => 'Onboarding',
    'inactive' => 'Inactive',
    _ => status.trim().isEmpty ? 'Active' : status.trim(),
  };
}

String volunteerStatusValue(String label) {
  return switch (label.trim().toLowerCase()) {
    'active' => 'active',
    'onboarding' || 'pending' => 'pending',
    'inactive' => 'inactive',
    _ => 'active',
  };
}
