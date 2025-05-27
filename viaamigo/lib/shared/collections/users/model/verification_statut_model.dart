import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationStatus {
  final List<Timestamp> emailVerificationReminders;
  final List<Timestamp> phoneVerificationReminders;
  final String? documentVerificationStatus; // "pending", "approved", "rejected"
  final String? documentVerificationFeedback;
  final Timestamp? lastVerificationAttempt;

  const VerificationStatus({
    this.emailVerificationReminders = const [],
    this.phoneVerificationReminders = const [],
    this.documentVerificationStatus,
    this.documentVerificationFeedback,
    this.lastVerificationAttempt,
  });

  factory VerificationStatus.fromMap(Map<String, dynamic> map) {
    return VerificationStatus(
      emailVerificationReminders:
          List<Timestamp>.from(map['email_verification_reminders'] ?? []),
      phoneVerificationReminders:
          List<Timestamp>.from(map['phone_verification_reminders'] ?? []),
      documentVerificationStatus: map['document_verification_status'],
      documentVerificationFeedback: map['document_verification_feedback'],
      lastVerificationAttempt: map['last_verification_attempt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email_verification_reminders': emailVerificationReminders,
      'phone_verification_reminders': phoneVerificationReminders,
      'document_verification_status': documentVerificationStatus,
      'document_verification_feedback': documentVerificationFeedback,
      'last_verification_attempt': lastVerificationAttempt,
    };
  }

  factory VerificationStatus.fromJson(Map<String, dynamic> json) =>
      VerificationStatus.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  VerificationStatus copyWith({
    List<Timestamp>? emailVerificationReminders,
    List<Timestamp>? phoneVerificationReminders,
    String? documentVerificationStatus,
    String? documentVerificationFeedback,
    Timestamp? lastVerificationAttempt,
  }) {
    return VerificationStatus(
      emailVerificationReminders:
          emailVerificationReminders ?? this.emailVerificationReminders,
      phoneVerificationReminders:
          phoneVerificationReminders ?? this.phoneVerificationReminders,
      documentVerificationStatus:
          documentVerificationStatus ?? this.documentVerificationStatus,
      documentVerificationFeedback:
          documentVerificationFeedback ?? this.documentVerificationFeedback,
      lastVerificationAttempt:
          lastVerificationAttempt ?? this.lastVerificationAttempt,
    );
  }
}
