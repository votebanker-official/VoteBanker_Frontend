class VrmVoterRecord {
  const VrmVoterRecord({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.epicNumber,
    this.sourceSerial,
    this.needsReview = false,
    this.reviewNotes,
    this.whatsappContact,
    this.instagramContact,
    this.facebookContact,
  });

  final String id;
  final String name;
  final int? age;
  final String? gender;
  final String? epicNumber;
  final int? sourceSerial;
  final bool needsReview;
  final String? reviewNotes;
  final String? whatsappContact;
  final String? instagramContact;
  final String? facebookContact;

  factory VrmVoterRecord.fromJson(Map<String, dynamic> json) {
    return VrmVoterRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse('${json['age'] ?? ''}'),
      gender: json['gender'] as String?,
      epicNumber: json['epicNumber'] as String? ?? json['epic_number'] as String?,
      sourceSerial: json['sourceSerial'] is int
          ? json['sourceSerial'] as int
          : int.tryParse('${json['sourceSerial'] ?? json['source_serial'] ?? ''}'),
      needsReview: json['needsReview'] == true || json['needs_review'] == true,
      reviewNotes: json['reviewNotes'] as String? ?? json['review_notes'] as String?,
      whatsappContact:
          json['whatsappContact'] as String? ?? json['whatsapp_contact'] as String?,
      instagramContact:
          json['instagramContact'] as String? ?? json['instagram_contact'] as String?,
      facebookContact:
          json['facebookContact'] as String? ?? json['facebook_contact'] as String?,
    );
  }

  VrmVoterRecord copyWithContacts({
    String? whatsappContact,
    String? instagramContact,
    String? facebookContact,
  }) {
    return VrmVoterRecord(
      id: id,
      name: name,
      age: age,
      gender: gender,
      epicNumber: epicNumber,
      sourceSerial: sourceSerial,
      needsReview: needsReview,
      reviewNotes: reviewNotes,
      whatsappContact: whatsappContact,
      instagramContact: instagramContact,
      facebookContact: facebookContact,
    );
  }
}
