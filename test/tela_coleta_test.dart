import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/presentation/screens/tela_coleta.dart';

import 'apoio.dart';

void main() {
  late RepositorioMemoria repositorio;
  late ServicoSimulado servico;

  setUp(() {
    repositorio = RepositorioMemoria();
    servico = ServicoSimulado();
  });

  tearDown(() async {
    if (!servico.controlador.isClosed) await servico.controlador.close();
  });

  Future<void> montar(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: TelaColeta(repositorio: repositorio, servico: servico),
    ),
  );

  Future<void> concluir(WidgetTester tester) async {
    // O cancelamento de streams pode usar um Future compartilhado da zona real.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('inicia só uma assinatura e habilita parar', (tester) async {
    await montar(tester);
    await tester.tap(find.text('Iniciar coleta'));
    await tester.tap(find.text('Iniciar coleta'));
    await tester.pump();
    expect(servico.assinaturas, 1);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Iniciar coleta'),
          )
          .onPressed,
      isNull,
    );
    servico.controlador.add(posicao());
    await tester.pump();
    expect(repositorio.registros.length, 1);
    await tester.tap(find.text('Parar coleta'));
    await concluir(tester);
    expect(servico.controlador.hasListener, isFalse);
    servico.controlador.add(posicao(2));
    await tester.pump();
    expect(repositorio.registros.length, 1);
    await tester.tap(find.text('Iniciar coleta'));
    await tester.pump();
    expect(servico.assinaturas, 2);
  });

  testWidgets('parar aguarda as gravações na ordem e sem sobreposição', (
    tester,
  ) async {
    final primeira = Completer<void>();
    var simultaneas = 0;
    var maximo = 0;
    final ordem = <int?>[];
    repositorio.aoInserir = (localizacao) async {
      simultaneas++;
      if (simultaneas > maximo) maximo = simultaneas;
      if (localizacao.id == 1) await primeira.future;
      ordem.add(localizacao.id);
      simultaneas--;
    };
    await montar(tester);
    await tester.tap(find.text('Iniciar coleta'));
    await tester.pump();
    for (var i = 1; i <= 3; i++) {
      servico.controlador.add(posicao(i));
    }
    await tester.pump();
    await tester.tap(find.text('Parar coleta'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Iniciar coleta'),
          )
          .onPressed,
      isNull,
    );
    primeira.complete();
    await concluir(tester);
    expect(ordem, [1, 2, 3]);
    expect(maximo, 1);
    expect(repositorio.registros.length, 3);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Iniciar coleta'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('trata falha de gravação e interrompe a coleta', (tester) async {
    repositorio.aoInserir = (_) async => throw StateError('falha simulada');
    await montar(tester);
    await tester.tap(find.text('Iniciar coleta'));
    await tester.pump();
    servico.controlador.add(posicao());
    await concluir(tester);
    expect(find.textContaining('salvar'), findsOneWidget);
    expect(servico.controlador.hasListener, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trata erro e encerramento do stream', (tester) async {
    await montar(tester);
    await tester.tap(find.text('Iniciar coleta'));
    await tester.pump();
    servico.controlador.addError(StateError('falha simulada'));
    await concluir(tester);
    expect(servico.controlador.hasListener, isFalse);
    expect(find.textContaining('localização'), findsWidgets);
    await tester.tap(find.text('Iniciar coleta'));
    await tester.pump();
    final fechamento = servico.controlador.close();
    await concluir(tester);
    await tester.runAsync(() => fechamento);
    await concluir(tester);
    expect(find.textContaining('encerrado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('não assina depois de desmontar durante a permissão', (
    tester,
  ) async {
    final autorizacao = Completer<void>();
    servico.autorizacao = autorizacao.future;
    await montar(tester);
    await tester.tap(find.text('Iniciar coleta'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    autorizacao.complete();
    await tester.pump();
    expect(servico.assinaturas, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orienta permissão negada e abre configurações', (tester) async {
    servico.erroPermissao = Exception(
      'Permissão negada. Use as configurações.',
    );
    await montar(tester);
    await tester.tap(find.text('Iniciar coleta'));
    await tester.pump();
    expect(find.textContaining('Permissão negada'), findsOneWidget);
    expect(servico.assinaturas, 0);
    await tester.tap(find.text('Configurações de permissão'));
    await tester.pump();
    expect(servico.configuracoesAbertas, isTrue);
  });
}
