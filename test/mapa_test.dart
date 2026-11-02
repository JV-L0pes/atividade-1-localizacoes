import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:localizacoes/features/localizacoes/presentation/screens/tela_mapa.dart';
import 'package:localizacoes/features/localizacoes/presentation/widgets/mapa_localizacoes.dart';

import 'apoio.dart';

class ProvedorLocal extends TileProvider {
  final imagem = MemoryImage(TileProvider.transparentImage);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      imagem;
}

class TileSimulado extends Fake implements TileImage {}

void main() {
  testWidgets('falha nas ruas avisa sem remover os marcadores', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapaLocalizacoes(
            localizacoes: [posicao()],
            tileProvider: ProvedorLocal(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final camada = tester.widget<TileLayer>(find.byType(TileLayer));
    camada.errorTileCallback!(TileSimulado(), StateError('sem rede'), null);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Não foi possível carregar as ruas'),
      findsOneWidget,
    );
    expect(find.byTooltip('Localização mais recente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('histórico vazio não tenta carregar tiles ou cache', (
    tester,
  ) async {
    var preparacoes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TelaMapa(
          repositorio: RepositorioMemoria(),
          prepararCache: () async {
            preparacoes++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma localização salva.'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
    expect(preparacoes, 0);
  });

  testWidgets('falha de consulta permite nova tentativa', (tester) async {
    final repositorio = RepositorioMemoria()
      ..erroConsulta = StateError('falha');
    await tester.pumpWidget(
      MaterialApp(
        home: TelaMapa(repositorio: repositorio, prepararCache: () async {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('carregar'), findsOneWidget);
    repositorio.erroConsulta = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma localização salva.'), findsOneWidget);
  });

  testWidgets('falha de cache preserva dados e oferece nova tentativa', (
    tester,
  ) async {
    final repositorio = RepositorioMemoria()..registros.add(posicao());
    await tester.pumpWidget(
      MaterialApp(
        home: TelaMapa(
          repositorio: repositorio,
          prepararCache: () async => throw StateError('diretório indisponível'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('carregar'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(repositorio.registros.length, 1);
    expect(find.byType(FlutterMap), findsNothing);
  });

  final grupos = <String, List<Localizacao>>{
    'um ponto': [posicao()],
    'pontos repetidos': [posicao(), posicao(2)],
    'mesma latitude': [
      posicao(),
      Localizacao(
        latitude: 1.23456789,
        longitude: 3,
        precisao: 1,
        instante: DateTime.utc(2026),
      ),
    ],
    'mesma longitude': [
      posicao(),
      Localizacao(
        latitude: 3,
        longitude: 2.34567891,
        precisao: 1,
        instante: DateTime.utc(2026),
      ),
    ],
    'pontos distintos': [
      posicao(),
      Localizacao(
        latitude: -1,
        longitude: -3,
        precisao: 1,
        instante: DateTime.utc(2026),
      ),
    ],
  };
  for (final grupo in grupos.entries) {
    testWidgets('enquadra ${grupo.key} sem zoom inválido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapaLocalizacoes(
              localizacoes: grupo.value,
              tileProvider: ProvedorLocal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final mapa = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(mapa.mapController!.camera.zoom.isFinite, isTrue);
      await tester.tap(find.byTooltip('Enquadrar todos os pontos'));
      await tester.pumpAndSettle();
      expect(mapa.mapController!.camera.zoom.isFinite, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mostra o mais recente em vermelho por cima e abre seus dados', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapaLocalizacoes(
            localizacoes: [posicao(2), posicao()],
            tileProvider: ProvedorLocal(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final camada = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(camada.markers.length, 2);
    final botao = camada.markers.last.child as IconButton;
    expect((botao.icon as Icon).color, Colors.red);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    await tester.tap(find.byTooltip('Localização mais recente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1.234568'), findsOneWidget);
    expect(find.textContaining('3.8 m'), findsOneWidget);
  });
}
