import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/mapa_localizacoes.dart';

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key, required this.repositorio, this.prepararCache});

  final RepositorioLocalizacoes repositorio;
  final Future<void> Function()? prepararCache;

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  late Future<List<Localizacao>> _consulta;

  @override
  void initState() {
    super.initState();
    _consulta = _carregar();
  }

  Future<List<Localizacao>> _carregar() async {
    final localizacoes = await widget.repositorio.consultar();
    if (localizacoes.isNotEmpty) {
      await (widget.prepararCache ?? prepararCacheMapa)();
    }
    return localizacoes;
  }

  void _atualizar() {
    setState(() {
      _consulta = _carregar();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Localizacao>>(
    future: _consulta,
    builder: (context, resultado) {
      final carregando = resultado.connectionState != ConnectionState.done;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mapa'),
          actions: [
            IconButton(
              onPressed: carregando ? null : _atualizar,
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(child: _conteudo(resultado, carregando)),
      );
    },
  );

  Widget _conteudo(
    AsyncSnapshot<List<Localizacao>> resultado,
    bool carregando,
  ) {
    if (carregando) return const Center(child: CircularProgressIndicator());
    if (resultado.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Não foi possível carregar o mapa. Seu histórico foi preservado.',
              ),
              TextButton(
                onPressed: _atualizar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (resultado.data!.isEmpty) {
      return const Center(child: Text('Nenhuma localização salva.'));
    }
    return MapaLocalizacoes(
      key: ObjectKey(_consulta),
      localizacoes: resultado.data!,
    );
  }
}
