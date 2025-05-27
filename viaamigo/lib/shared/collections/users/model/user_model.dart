import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:viaamigo/shared/collections/users/model/verification_statut_model.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final DateTime? birthday;
  final String role;
  final String? profilePicture;
  final String? provider;
  final bool emailVerified;
  final bool phoneVerified;
  final bool acceptsTerms;
  final String? acceptedTermsVersion;
  final DateTime createdAt;
  final GeoPoint? location;
  final bool isPro;
  final bool isBanned;
  final String status;
  final UserStats stats;
  final String? currentTripId;
  final String? referralCode;
  final String? referredBy;
  final double walletBalance;
  final VerificationStatus? verificationStatus;
  final List<String> blockedUsers;
  final Map<String, dynamic>? emergencyContact;
  final Timestamp? termsAcceptedAt;
  final String? appVersion;
final String? devicePlatform;
final String? deactivationReason;
final String? language;
final DateTime? lastLoginAt;



  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.birthday,
    required this.role,
    this.profilePicture,
    required this.provider,
    required this.emailVerified,
    required this.phoneVerified,
    required this.acceptsTerms,
    this.acceptedTermsVersion,
    required this.createdAt,
    this.location,
    required this.isPro,
    required this.isBanned,
    required this.status,
    required this.stats,
    this.currentTripId,
    this.referralCode,
    this.referredBy,
    required this.walletBalance,
    this.verificationStatus,
    required this.blockedUsers,
    this.emergencyContact,
    this.termsAcceptedAt,
    this.appVersion,
    this.devicePlatform,
    this.deactivationReason,
    this.language,
    this.lastLoginAt,


  });
    /// 🖼️ Retourne une URL sûre pour l'image de profil (placeholder si vide ou null)
  String get safeProfilePicture {
    if (profilePicture != null && profilePicture!.isNotEmpty) {
      return profilePicture!;
    }
    // Placeholder généré avec nom/prénom
    final formattedName = Uri.encodeComponent('$firstName $lastName');
    return 'https://ui-avatars.com/api/?name=$formattedName&background=random';
  }


  /// 🔁 Permet de cloner l'utilisateur avec des champs modifiés
  UserModel copyWith({
  String? firstName,
  String? lastName,
  String? email,
  String? phone,
  DateTime? birthday,
  String? role,
  String? profilePicture,
  String? provider,
  bool? emailVerified,
  bool? phoneVerified,
  bool? acceptsTerms,
  String? acceptedTermsVersion,
  DateTime? createdAt,
  GeoPoint? location,
  bool? isPro,
  bool? isBanned,
  String? status,
  UserStats? stats,
  String? currentTripId,
  String? referralCode,
  String? referredBy,
  double? walletBalance,
  VerificationStatus? verificationStatus,
  List<String>? blockedUsers,
  Map<String, dynamic>? emergencyContact,
  Timestamp? termsAcceptedAt,
  String? appVersion,
String? devicePlatform,
String? deactivationReason,
String? language,
DateTime? lastLoginAt,

  
}) {
  return UserModel(
    uid: uid,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    birthday: birthday ?? this.birthday,
    role: role ?? this.role,
    profilePicture: profilePicture ?? this.profilePicture,
    provider: provider ?? this.provider,
    emailVerified: emailVerified ?? this.emailVerified,
    phoneVerified: phoneVerified ?? this.phoneVerified,
    acceptsTerms: acceptsTerms ?? this.acceptsTerms,
    acceptedTermsVersion: acceptedTermsVersion ?? this.acceptedTermsVersion,
    createdAt: createdAt ?? this.createdAt,
    location: location ?? this.location,
    isPro: isPro ?? this.isPro,
    isBanned: isBanned ?? this.isBanned,
    status: status ?? this.status,
    stats: stats ?? this.stats,
    currentTripId: currentTripId ?? this.currentTripId,
    referralCode: referralCode ?? this.referralCode,
    referredBy: referredBy ?? this.referredBy,
    walletBalance: walletBalance ?? this.walletBalance,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    blockedUsers: blockedUsers ?? this.blockedUsers,
    emergencyContact: emergencyContact ?? this.emergencyContact,
    termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt, // ✅ LA BONNE PLACE
    appVersion: appVersion ?? this.appVersion,
devicePlatform: devicePlatform ?? this.devicePlatform,
deactivationReason: deactivationReason ?? this.deactivationReason,
language: language ?? this.language,
lastLoginAt: lastLoginAt ?? this.lastLoginAt,

  );
}


  /// 🔄 Conversion depuis Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      birthday: data['birthday'] != null ? (data['birthday'] as Timestamp).toDate() : null,
      role: data['role'] ?? 'expediteur',
      profilePicture: data['profilePicture'],
      provider: data['provider'] ?? 'email',
      emailVerified: data['emailVerified'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      acceptsTerms: data['acceptsTerms'] ?? false,
      acceptedTermsVersion: data['acceptedTermsVersion'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      location: data['location'],
      isPro: data['isPro'] ?? false,
      isBanned: data['isBanned'] ?? false,
      status: data['status'] ?? 'active',
      stats: UserStats.fromMap(data['stats'] ?? {}),
      currentTripId: data['currentTripId'],
      referralCode: data['referralCode'],
      referredBy: data['referredBy'],
      walletBalance: (data['walletBalance'] ?? 0).toDouble(),
          termsAcceptedAt: data['termsAcceptedAt'] != null 
        ? data['termsAcceptedAt'] as Timestamp 
        : null,
      verificationStatus: data['verification_status'] != null
    ? VerificationStatus.fromMap(data['verification_status'])
    : null,

      blockedUsers: List<String>.from(data['blocked_users'] ?? []),
      emergencyContact: data['emergency_contact'],
      appVersion: data['appVersion'],
devicePlatform: data['devicePlatform'],
deactivationReason: data['deactivationReason'],
language: data['language'],
lastLoginAt: data['lastLoginAt'] != null ? (data['lastLoginAt'] as Timestamp).toDate() : null,

      
      
    );
  }

  /// 🔄 Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'role': role,
      'profilePicture': profilePicture,
      'provider': provider,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'acceptsTerms': acceptsTerms,
      'acceptedTermsVersion': acceptedTermsVersion,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'isPro': isPro,
      'isBanned': isBanned,
      'status': status,
      'stats': stats.toMap(),
      'currentTripId': currentTripId,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'walletBalance': walletBalance,
      'verification_status': verificationStatus?.toMap(),
      'blocked_users': blockedUsers,
      'emergency_contact': emergencyContact,
      'termsAcceptedAt': termsAcceptedAt,
      'appVersion': appVersion,
    'devicePlatform': devicePlatform,
    'deactivationReason': deactivationReason,
    'language': language,
    'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,

    };
  }

  /// 🌐 Utilisable pour toJson / API / stockage local
  Map<String, dynamic> toJson() => toFirestore();

  /// 🌐 Utilisable pour fromJson / stockage local
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      birthday: json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      role: json['role'],
      profilePicture: json['profilePicture'],
      provider: json['provider'],
      emailVerified: json['emailVerified'],
      phoneVerified: json['phoneVerified'],
      acceptsTerms: json['acceptsTerms'],
      acceptedTermsVersion: json['acceptedTermsVersion'],
      createdAt: DateTime.parse(json['createdAt']),
      location: json['location'], // Attention : nécessite traitement si GeoPoint
      isPro: json['isPro'],
      isBanned: json['isBanned'],
      status: json['status'],
      stats: UserStats.fromMap(json['stats']),
      currentTripId: json['currentTripId'],
      referralCode: json['referralCode'],
      referredBy: json['referredBy'],
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
       termsAcceptedAt: json['termsAcceptedAt'],
      verificationStatus: json['verification_status'] != null
    ? VerificationStatus.fromJson(json['verification_status'])
    : null,

      blockedUsers: List<String>.from(json['blocked_users'] ?? []),
      emergencyContact: json['emergency_contact'],
      appVersion: json['appVersion'],
devicePlatform: json['devicePlatform'],
deactivationReason: json['deactivationReason'],
language: json['language'],
lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt']) : null,

    );
  }

  /// Comparaison logique entre deux utilisateurs
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
class UserStats {
  final int totalDeliveries;
  final int totalTrips;
  final double avgRating;
  final double revenue;
  final double co2Saved;
  final double completionRate;
  final double responseTime;
  final double totalDistance;

  const UserStats({
    this.totalDeliveries = 0,
    this.totalTrips = 0,
    this.avgRating = 0.0,
    this.revenue = 0.0,
    this.co2Saved = 0.0,
    this.completionRate = 0.0,
    this.responseTime = 0.0,
    this.totalDistance = 0.0,
  });

  factory UserStats.fromMap(Map<String, dynamic> data) {
    return UserStats(
      totalDeliveries: int.tryParse(data['totalDeliveries'].toString()) ?? 0,
      totalTrips: data['totalTrips'] ?? 0,
      avgRating: (data['avgRating'] ?? 0).toDouble(),
      revenue: (data['revenue'] ?? 0).toDouble(),
      co2Saved: (data['co2Saved'] ?? 0).toDouble(),
      completionRate: (data['completionRate'] ?? 0).toDouble(),
      responseTime: (data['responseTime'] ?? 0).toDouble(),
      totalDistance: (data['totalDistance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalDeliveries': totalDeliveries,
      'totalTrips': totalTrips,
      'avgRating': avgRating,
      'revenue': revenue,
      'co2Saved': co2Saved,
      'completionRate': completionRate,
      'responseTime': responseTime,
      'totalDistance': totalDistance,
    };
  }

  UserStats copyWith({
    int? totalDeliveries,
    int? totalTrips,
    double? avgRating,
    double? revenue,
    double? co2Saved,
    double? completionRate,
    double? responseTime,
    double? totalDistance,
  }) {
    return UserStats(
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalTrips: totalTrips ?? this.totalTrips,
      avgRating: avgRating ?? this.avgRating,
      revenue: revenue ?? this.revenue,
      co2Saved: co2Saved ?? this.co2Saved,
      completionRate: completionRate ?? this.completionRate,
      responseTime: responseTime ?? this.responseTime,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStats &&
          totalDeliveries == other.totalDeliveries &&
          totalTrips == other.totalTrips &&
          avgRating == other.avgRating;

  @override
  int get hashCode =>
      totalDeliveries.hashCode ^
      totalTrips.hashCode ^
      avgRating.hashCode;
}
