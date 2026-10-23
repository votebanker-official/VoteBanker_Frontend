import 'package:flutter/services.dart';

/// Extracts the 10-digit national number from an Indian phone number string.
///
/// Strips country code prefixes (+91 or 91) and leading trunk 0s.
String extractIndianNationalNumber(String input) {
  final trimmed = input.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) {
    return digits.substring(2);
  }
  if (digits.length == 11 && digits.startsWith('0')) {
    return digits.substring(1);
  }
  if (digits.length > 10 && digits.startsWith('91')) {
    return digits.substring(digits.length - 10);
  }
  if (digits.length > 10) {
    return digits.substring(0, 10);
  }
  return digits;
}

/// Validates whether [input] is a valid 10-digit Indian mobile number.
///
/// Must contain exactly 10 numeric digits and begin with 6, 7, 8, or 9.
/// Rejects empty input, numbers starting with 0–5, numbers with fewer or more
/// than 10 digits, letters, and non-Indian international prefixes.
bool isValidContactNumber(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  // Reject input containing letters
  if (RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
    return false;
  }

  // If international prefix is present, reject if not +91
  final nonPunct = trimmed.replaceAll(RegExp(r'[\s\-()]'), '');
  if (nonPunct.startsWith('+') && !nonPunct.startsWith('+91')) {
    return false;
  }

  final digits = nonPunct.replaceAll(RegExp(r'\D'), '');
  final String national;
  if (digits.length == 12 && digits.startsWith('91')) {
    national = digits.substring(2);
  } else if (digits.length == 11 && digits.startsWith('0')) {
    national = digits.substring(1);
  } else if (digits.length == 10) {
    national = digits;
  } else {
    return false;
  }

  return RegExp(r'^[6-9]\d{9}$').hasMatch(national);
}

/// Text input formatter for Indian 10-digit mobile numbers.
///
/// Allows only numeric digits (0–9), caps at exactly 10 digits,
/// and automatically strips leading country codes (+91, 91) or trunk 0 when pasted.
class IndianMobileNumberFormatter extends TextInputFormatter {
  const IndianMobileNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    var digits = text.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
