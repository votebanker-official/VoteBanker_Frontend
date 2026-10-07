class LetterDraft {
  const LetterDraft({
    required this.senderName,
    required this.senderAddress,
    required this.mobile,
    required this.email,
    required this.politicianName,
    required this.designation,
    required this.designationDetail,
    required this.constituency,
    required this.subject,
    required this.purpose,
    required this.message,
    required this.date,
  });

  final String senderName;
  final String senderAddress;
  final String mobile;
  final String email;
  final String politicianName;
  final String designation;
  final String designationDetail;
  final String constituency;
  final String subject;
  final String purpose;
  final String message;
  final DateTime date;

  String get dateIso {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Map<String, dynamic> toJson() {
    return {
      'senderName': senderName.trim(),
      'senderAddress': senderAddress.trim(),
      'mobile': mobile.trim(),
      'email': email.trim(),
      'politicianName': politicianName.trim(),
      'designation': designation,
      'designationDetail': designationDetail.trim(),
      'constituency': constituency.trim(),
      'subject': subject.trim(),
      'purpose': purpose.trim(),
      'message': message.trim(),
      'date': dateIso,
    };
  }
}

const letterDesignations = <String, String>{
  'MLA': 'letterRoleMla',
  'MP': 'letterRoleMp',
  'Minister': 'letterRoleMinister',
  'Councillor': 'letterRoleCouncillor',
  'Mayor': 'letterRoleMayor',
  'Other': 'letterRoleOther',
};

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _mobilePattern = RegExp(r'^[\d+\-()\s]{8,20}$');

Map<String, String> letterFieldErrors(LetterDraft draft) {
  final errors = <String, String>{};
  if (draft.senderName.trim().isEmpty) {
    errors['senderName'] = 'letterNeedSender';
  }
  if (draft.politicianName.trim().isEmpty) {
    errors['politicianName'] = 'letterNeedPolitician';
  }
  if (!letterDesignations.containsKey(draft.designation)) {
    errors['designation'] = 'letterNeedDesignation';
  }
  if (draft.designation == 'Other' && draft.designationDetail.trim().isEmpty) {
    errors['designationDetail'] = 'letterNeedDesignationDetail';
  }
  if (draft.constituency.trim().isEmpty) {
    errors['constituency'] = 'letterNeedConstituency';
  }
  if (draft.subject.trim().isEmpty) {
    errors['subject'] = 'letterNeedSubject';
  }
  if (draft.purpose.trim().isEmpty) {
    errors['purpose'] = 'letterNeedPurpose';
  }
  if (draft.message.trim().isEmpty) {
    errors['message'] = 'letterNeedMessage';
  }
  if (draft.email.trim().isNotEmpty && !_emailPattern.hasMatch(draft.email.trim())) {
    errors['email'] = 'letterNeedEmail';
  }
  if (draft.mobile.trim().isNotEmpty && !_mobilePattern.hasMatch(draft.mobile.trim())) {
    errors['mobile'] = 'letterNeedMobile';
  }
  return errors;
}

class GeneratedLetter {
  const GeneratedLetter({
    required this.text,
    required this.source,
    required this.subject,
    required this.senderName,
    required this.politicianName,
  });

  final String text;
  final String source;
  final String subject;
  final String senderName;
  final String politicianName;

  bool get isMock => source == 'mock';

  GeneratedLetter copyWith({String? text}) {
    return GeneratedLetter(
      text: text ?? this.text,
      source: source,
      subject: subject,
      senderName: senderName,
      politicianName: politicianName,
    );
  }

  factory GeneratedLetter.fromJson(Map<String, dynamic> json) {
    return GeneratedLetter(
      text: json['text'] as String? ?? '',
      source: json['source'] as String? ?? 'mock',
      subject: json['subject'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      politicianName: json['politicianName'] as String? ?? '',
    );
  }
}

String letterFileName(String subject) {
  final cleaned = subject
      .replaceAll(RegExp(r'[<>:"/\\|?*\n\r]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final base = cleaned.isEmpty ? 'official-letter' : cleaned;
  return '$base.pdf';
}
