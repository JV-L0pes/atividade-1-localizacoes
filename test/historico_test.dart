import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/presentation/screens/tela_localizacoes.dart';

import 'apoio.dart';

void main() {
  late RepositorioMemoria repositorio;
  setUp(() => repositorio = RepositorioMemoria());

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TelaLocalizacoes(
          repositorio: repositorio,
          coletaAtiva: () => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('formata coordenadas, precisão e hora local', (tester) async {
    repositorio.registros.add(posicao());
    await montar(tester);
    expect(find.textContaining('1.234568'), findsOneWidget);
    expect(find.textContaining('2.345679'), findsOneWidget);
    expect(find.textContaining('3.8 m'), findsOneWidget);
    final horaLocal = posicao().instante.toLocal();
    final hora = horaLocal.hour.toString().padLeft(2, '0');
    expect(find.textContaining('$hora:04:01'), findsOneWidget);
    expect(find.textContaining('02/11/2026'), findsOneWidget);
  });

  testWidgets('cancelar preserva dados e avisa da coleta ativa', (
    tester,
  ) async {
    repositorio.registros.add(posicao());
    await montar(tester);
    await tester.tap(find.byTooltip('Limpar histórico'));
    await tester.pumpAndSettle();
    expect(find.textContaining('permanente'), findsOneWidget);
    expect(find.textContaining('continuarão sendo salvos'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repositorio.registros.length, 1);
    expect(repositorio.limpezas, 0);
  });

  testWidgets('limpa, confirma sucesso e atualiza com novas posições', (
    tester,
  ) async {
    repositorio.registros.add(posicao());
    await montar(tester);
    await tester.tap(find.byTooltip('Limpar histórico'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Limpar histórico'));
    await tester.pumpAndSettle();
    expect(repositorio.registros, isEmpty);
    expect(find.text('Histórico limpo.'), findsOneWidget);
    expect(find.text('Nenhuma localização salva.'), findsOneWidget);
    await repositorio.inserir(posicao(2));
    await tester.tap(find.byTooltip('Atualizar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1.234568'), findsOneWidget);
  });

  testWidgets('consulta com falha permite nova tentativa', (tester) async {
    repositorio.erroConsulta = StateError('falha simulada');
    await montar(tester);
    expect(find.textContaining('carregar'), findsOneWidget);
    repositorio.erroConsulta = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma localização salva.'), findsOneWidget);
  });

  testWidgets('falha ao limpar não anuncia sucesso nem remove a lista', (
    tester,
  ) async {
    repositorio.registros.add(posicao());
    repositorio.erroLimpeza = StateError('falha simulada');
    await montar(tester);
    await tester.tap(find.byTooltip('Limpar histórico'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Limpar histórico'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível limpar'), findsOneWidget);
    expect(find.text('Histórico limpo.'), findsNothing);
    expect(find.textContaining('1.234568'), findsOneWidget);
  });
}
