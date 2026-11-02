import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  BancoLocalizacoes({
    this._caminho,
    Future<Database> Function(String, OpenDatabaseOptions)? abrir,
  }) : _abrir =
           abrir ??
           ((caminho, opcoes) =>
               databaseFactory.openDatabase(caminho, options: opcoes));

  final String? _caminho;
  final Future<Database> Function(String, OpenDatabaseOptions) _abrir;
  Future<Database>? _conexao;

  Future<Database> get conexao => _conexao ??= _abrirBanco();

  Future<Database> _abrirBanco() async {
    try {
      final caminho =
          _caminho ?? p.join(await getDatabasesPath(), 'localizacoes.db');
      return await _abrir(
        caminho,
        OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) => db.execute('''
            CREATE TABLE localizacoes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              precisao REAL NOT NULL,
              instante TEXT NOT NULL
            )
          '''),
        ),
      );
    } catch (_) {
      _conexao = null;
      rethrow;
    }
  }

  Future<void> fechar() async {
    final conexao = _conexao;
    if (conexao == null) return;
    try {
      await (await conexao).close();
    } finally {
      _conexao = null;
    }
  }
}
