import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

class RepositorioLocalizacoes {
  RepositorioLocalizacoes(this._banco);

  final BancoLocalizacoes _banco;

  Future<void> inserir(Localizacao localizacao) async {
    final db = await _banco.conexao;
    await db.insert('localizacoes', localizacao.toMap());
  }

  Future<List<Localizacao>> consultar() async {
    final db = await _banco.conexao;
    final registros = await db.query(
      'localizacoes',
      orderBy: 'instante DESC, id DESC',
      limit: 100,
    );
    return registros.map(Localizacao.fromMap).toList();
  }

  Future<void> limpar() async {
    final db = await _banco.conexao;
    await db.delete('localizacoes');
  }
}
