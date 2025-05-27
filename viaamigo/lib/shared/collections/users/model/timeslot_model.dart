

/// 📆 Modèle représentant un créneau horaire récurrent dans la semaine
/// Utilisé pour planifier la disponibilité (chauffeurs, envois, etc.)
class TimeSlot {
  final String day;       // Jour de la semaine (ex: "monday", "tuesday")
  final String start;     // Heure de début au format "HH:MM"
  final String end;       // Heure de fin au format "HH:MM"

  /// ✅ Constructeur principal
  const TimeSlot({
    required this.day,
    required this.start,
    required this.end,
  });

  /// 🔄 Création depuis une Map Firestore
  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      day: map['day'] ?? '',
      start: map['start'] ?? '00:00',
      end: map['end'] ?? '00:00',
    );
  }

  /// 🔄 Conversion en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'start': start,
      'end': end,
    };
  }

  /// 🔄 Alias toMap() pour un usage JSON/API
  Map<String, dynamic> toJson() => toMap();

  /// 🔁 Création depuis un JSON (ex: stockage local)
  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot.fromMap(json);

  /// 🧪 Comparaison logique entre deux TimeSlot
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot &&
        other.day == day &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => day.hashCode ^ start.hashCode ^ end.hashCode;

  /// 🛠️ Clone modifiable
  TimeSlot copyWith({
    String? day,
    String? start,
    String? end,
  }) {
    return TimeSlot(
      day: day ?? this.day,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}
