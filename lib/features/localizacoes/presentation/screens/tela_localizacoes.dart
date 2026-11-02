import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/item_localizacao.dart';

class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({
    super.key,
    required this.repositorio,
    required this.coletaAtiva,
  });

  final RepositorioLocalizacoes repositorio;
  final bool Function() coletaAtiva;

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  late Future<List<Localizacao>> _consulta;
  bool _limpando = false;

  @override
  void initState() {
    super.initState();
    _consulta = widget.repositorio.consultar();
  }

  void _atualizar() {
    setState(() {
      _consulta = widget.repositorio.consultar();
    });
  }

  Future<void> _confirmarLimpeza() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar todo o histórico?'),
        content: Text(
          'A exclusão de todas as localizações é permanente, incluindo registros '
          'anteriores aos 100 exibidos.'
          '${widget.coletaAtiva() ? '\nA coleta está ativa: novos registros continuarão sendo salvos.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _limpando = true);
    try {
      await widget.repositorio.limpar();
      if (!mounted) return;
      _atualizar();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Histórico limpo.')));
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível limpar o histórico: $erro')),
        );
      }
    } finally {
      if (mounted) setState(() => _limpando = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Localizacao>>(
    future: _consulta,
    builder: (context, resultado) {
      final ocupada =
          _limpando || resultado.connectionState != ConnectionState.done;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Histórico'),
          actions: [
            IconButton(
              onPressed: ocupada ? null : _atualizar,
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: ocupada ? null : _confirmarLimpeza,
              tooltip: 'Limpar histórico',
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: SafeArea(child: _conteudo(resultado, ocupada)),
      );
    },
  );

  Widget _conteudo(AsyncSnapshot<List<Localizacao>> resultado, bool ocupada) {
    if (ocupada) return const Center(child: CircularProgressIndicator());
    if (resultado.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível carregar o histórico.'),
              TextButton(
                onPressed: _atualizar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    final localizacoes = resultado.data!;
    if (localizacoes.isEmpty) {
      return const Center(child: Text('Nenhuma localização salva.'));
    }
    return ListView.separated(
      itemCount: localizacoes.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          ItemLocalizacao(localizacao: localizacoes[index]),
    );
  }
}
