import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/data/database/banco_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory pasta;
  late BancoLocalizacoes banco;
  late RepositorioLocalizacoes repositorio;

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('localizacoes_teste_');
    banco = BancoLocalizacoes(
      caminho: p.join(pasta.path, 'localizacoes.db'),
      abrir: (caminho, opcoes) =>
          databaseFactoryFfi.openDatabase(caminho, options: opcoes),
    );
    repositorio = RepositorioLocalizacoes(banco);
  });

  tearDown(() async {
    await banco.fechar();
    await pasta.delete(recursive: true);
  });

  Localizacao posicao(DateTime instante) =>
      Localizacao(latitude: 1, longitude: 2, precisao: 3, instante: instante);

  test('consulta os últimos 100 sem excluir os anteriores', () async {
    for (var i = 0; i < 105; i++) {
      await repositorio.inserir(posicao(DateTime.utc(2026, 11, 2, 0, 0, i)));
    }
    final registros = await repositorio.consultar();
    expect(registros.length, 100);
    expect(registros.first.id, 105);
    expect(registros.last.id, 6);
    final db = await banco.conexao;
    expect(
      (await db.rawQuery('SELECT COUNT(*) AS total FROM localizacoes'))
          .single['total'],
      105,
    );
  });

  test(
    'ordena pelo instante, inclusive frações, e desempata pelo id',
    () async {
      await repositorio.inserir(
        posicao(DateTime.utc(2026, 11, 2, 0, 0, 0, 0, 1)),
      );
      await repositorio.inserir(posicao(DateTime.utc(2026, 11, 2)));
      await repositorio.inserir(
        posicao(DateTime.utc(2026, 11, 2, 0, 0, 0, 0, 1)),
      );
      expect((await repositorio.consultar()).map((l) => l.id), [3, 1, 2]);
    },
  );

  test('limpa todas as linhas, preservando banco e tabela', () async {
    for (var i = 0; i < 105; i++) {
      await repositorio.inserir(posicao(DateTime.utc(2026)));
    }
    await repositorio.limpar();
    expect(await repositorio.consultar(), isEmpty);
    final db = await banco.conexao;
    expect(await File(db.path).exists(), isTrue);
    expect(
      (await db.rawQuery('SELECT COUNT(*) AS total FROM localizacoes'))
          .single['total'],
      0,
    );
    await repositorio.inserir(posicao(DateTime.utc(2026)));
    expect((await repositorio.consultar()).single.id, 106);
  });

  test('preserva os dados após fechar e reabrir', () async {
    await repositorio.inserir(posicao(DateTime.utc(2026)));
    await banco.fechar();
    expect((await repositorio.consultar()).single.latitude, 1);
  });

  test('reutiliza abertura concorrente e permite retry após falha', () async {
    var tentativas = 0;
    final comFalha = BancoLocalizacoes(
      caminho: inMemoryDatabasePath,
      abrir: (caminho, opcoes) async {
        if (++tentativas == 1) throw StateError('falha simulada');
        return databaseFactoryFfi.openDatabase(caminho, options: opcoes);
      },
    );
    await expectLater(comFalha.conexao, throwsStateError);
    final conexoes = await Future.wait([comFalha.conexao, comFalha.conexao]);
    expect(tentativas, 2);
    expect(identical(conexoes.first, conexoes.last), isTrue);
    await comFalha.fechar();
  });
}
