import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';

void main() {
  test('converte os valores e o instante para UTC', () {
    final original = Localizacao(
      latitude: 1.25,
      longitude: -2.5,
      precisao: 3.75,
      instante: DateTime.parse('2026-11-02T12:00:00-03:00'),
    );
    final mapa = original.toMap();
    expect(mapa['instante'], '2026-11-02T15:00:00.000000Z');
    expect(mapa.containsKey('id'), isFalse);
    final recuperada = Localizacao.fromMap({...mapa, 'id': 7});
    expect(recuperada.id, 7);
    expect(recuperada.latitude, 1.25);
    expect(recuperada.longitude, -2.5);
    expect(recuperada.precisao, 3.75);
    expect(recuperada.instante, DateTime.utc(2026, 11, 2, 15));
    expect(recuperada.instante.isUtc, isTrue);
  });

  test('aceita valores inteiros retornados pelo SQLite', () {
    final localizacao = Localizacao.fromMap({
      'id': 1,
      'latitude': 0,
      'longitude': 0,
      'precisao': 1,
      'instante': '2026-11-02T15:00:00.000000Z',
    });
    expect(localizacao.latitude, 0.0);
    expect(localizacao.precisao, 1.0);
  });

  for (final (latitude, longitude, precisao) in [
    (91.0, 0.0, 1.0),
    (-91.0, 0.0, 1.0),
    (0.0, 181.0, 1.0),
    (0.0, -181.0, 1.0),
    (double.nan, 0.0, 1.0),
    (0.0, double.infinity, 1.0),
    (0.0, 0.0, -1.0),
    (0.0, 0.0, double.nan),
  ]) {
    test('rejeita posição inválida ($latitude, $longitude, $precisao)', () {
      expect(
        () => Localizacao(
          latitude: latitude,
          longitude: longitude,
          precisao: precisao,
          instante: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
    });
  }
}
