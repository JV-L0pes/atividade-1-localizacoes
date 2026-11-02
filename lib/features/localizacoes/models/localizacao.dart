class Localizacao {
  Localizacao({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.precisao,
    required this.instante,
  }) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude inválida.');
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude inválida.');
    }
    if (!precisao.isFinite || precisao < 0) {
      throw ArgumentError('Precisão inválida.');
    }
  }

  final int? id;
  final double latitude;
  final double longitude;
  final double precisao;
  final DateTime instante;

  Map<String, Object?> toMap() {
    final utc = instante.toUtc();
    final iso = utc.toIso8601String();
    return {
      if (id != null) 'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'precisao': precisao,
      // Frações de tamanho fixo mantêm a ordenação cronológica no SQLite.
      'instante': utc.microsecond == 0 ? iso.replaceFirst('Z', '000Z') : iso,
    };
  }

  factory Localizacao.fromMap(Map<String, Object?> mapa) => Localizacao(
    id: mapa['id'] as int?,
    latitude: (mapa['latitude'] as num).toDouble(),
    longitude: (mapa['longitude'] as num).toDouble(),
    precisao: (mapa['precisao'] as num).toDouble(),
    instante: DateTime.parse(mapa['instante'] as String).toUtc(),
  );
}
