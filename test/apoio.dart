import 'dart:async';

import 'package:localizacoes/features/localizacoes/data/database/banco_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:localizacoes/features/localizacoes/services/servico_localizacao.dart';

Localizacao posicao([int numero = 1]) => Localizacao(
  id: numero,
  latitude: 1.23456789,
  longitude: 2.34567891,
  precisao: 3.75,
  instante: DateTime.utc(2026, 11, 2, 15, 4, numero),
);

class RepositorioMemoria extends RepositorioLocalizacoes {
  RepositorioMemoria() : super(BancoLocalizacoes());

  final registros = <Localizacao>[];
  Future<void> Function(Localizacao)? aoInserir;
  Object? erroConsulta;
  Object? erroLimpeza;
  int limpezas = 0;

  @override
  Future<void> inserir(Localizacao localizacao) async {
    await aoInserir?.call(localizacao);
    registros.insert(0, localizacao);
  }

  @override
  Future<List<Localizacao>> consultar() async {
    if (erroConsulta case final erro?) throw erro;
    return registros.take(100).toList();
  }

  @override
  Future<void> limpar() async {
    if (erroLimpeza case final erro?) throw erro;
    limpezas++;
    registros.clear();
  }
}

class ServicoSimulado extends ServicoLocalizacao {
  ServicoSimulado() {
    controlador = StreamController<Localizacao>.broadcast(
      onListen: () => assinaturas++,
    );
  }

  late final StreamController<Localizacao> controlador;
  int assinaturas = 0;
  Future<void>? autorizacao;
  Object? erroPermissao;
  bool configuracoesAbertas = false;

  @override
  Future<void> verificarPermissoes() async {
    await autorizacao;
    if (erroPermissao case final erro?) throw erro;
  }

  @override
  Stream<Localizacao> posicoes() => controlador.stream;

  @override
  Future<bool> abrirConfiguracoes() async {
    configuracoesAbertas = true;
    return true;
  }
}
