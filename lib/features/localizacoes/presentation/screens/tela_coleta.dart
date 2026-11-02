import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import 'tela_localizacoes.dart';

class TelaColeta extends StatefulWidget {
  const TelaColeta({
    super.key,
    required this.repositorio,
    required this.servico,
  });

  final RepositorioLocalizacoes repositorio;
  final ServicoLocalizacao servico;

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  StreamSubscription<Localizacao>? _assinatura;
  Future<void> _gravacoes = Future.value();
  Future<void>? _parada;
  bool _ativa = false;
  bool _alterando = false;
  String? _erro;
  String? _mensagem;

  Future<void> _iniciar() async {
    if (_ativa || _alterando) return;
    setState(() {
      _alterando = true;
      _mensagem = null;
    });
    try {
      await widget.servico.verificarPermissoes();
      if (!mounted) return;
      final ciclo = WidgetsBinding.instance.lifecycleState;
      if (ciclo != null && ciclo != AppLifecycleState.resumed) {
        throw Exception('Volte ao aplicativo e toque em Iniciar coleta.');
      }
      _erro = null;
      _gravacoes = Future.value();
      _assinatura = widget.servico.posicoes().listen(
        (localizacao) {
          _gravacoes = _gravacoes
              .then((_) async {
                if (_erro != null) return;
                await widget.repositorio.inserir(localizacao);
              })
              .catchError((Object erro) {
                _falhar(
                  'Não foi possível salvar a posição. Coleta interrompida: $erro',
                );
              });
        },
        onError: (Object erro) => _falhar('Falha de localização: $erro'),
        onDone: () => _falhar('O stream de localização foi encerrado.'),
      );
      setState(() => _ativa = true);
    } catch (erro) {
      if (mounted) setState(() => _mensagem = erro.toString());
    } finally {
      if (mounted) setState(() => _alterando = false);
    }
  }

  void _falhar(String mensagem) {
    _erro ??= mensagem;
    unawaited(_parar());
  }

  Future<void> _parar() => _parada ??= _encerrarColeta();

  Future<void> _encerrarColeta() async {
    if (mounted) setState(() => _alterando = true);
    try {
      await _assinatura?.cancel();
      _assinatura = null;
    } catch (erro) {
      _erro ??= 'Não foi possível parar a localização. Tente novamente: $erro';
    }
    await _gravacoes;
    if (mounted) {
      setState(() {
        _ativa = _assinatura != null;
        _alterando = false;
        _mensagem = _erro ?? 'Coleta parada. Posições recebidas salvas.';
      });
    }
    _parada = null;
  }

  Future<void> _abrirConfiguracoes() async {
    try {
      final abriu = await widget.servico.abrirConfiguracoes();
      if (!abriu && mounted) {
        setState(() => _mensagem = 'Não foi possível abrir as configurações.');
      }
    } catch (erro) {
      if (mounted) {
        setState(() => _mensagem = 'Erro ao abrir as configurações: $erro');
      }
    }
  }

  @override
  void dispose() {
    final assinatura = _assinatura;
    _assinatura = null;
    if (assinatura != null) {
      unawaited(
        assinatura.cancel().catchError((Object erro, StackTrace pilha) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: erro,
              stack: pilha,
              library: 'coleta de localização',
            ),
          );
        }),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Localizações')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(_ativa ? Icons.location_on : Icons.location_off, size: 56),
          const SizedBox(height: 16),
          Text(
            _ativa ? 'Coleta ativa' : 'Coleta parada',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'As posições ficam salvas somente neste aparelho. '
            'Intervalo solicitado: 20 segundos. '
            'A coleta continua ao minimizar o aplicativo.',
          ),
          const SizedBox(height: 24),
          if (_mensagem != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Semantics(liveRegion: true, child: Text(_mensagem!)),
            ),
          FilledButton(
            onPressed: _ativa || _alterando ? null : _iniciar,
            child: const Text('Iniciar coleta'),
          ),
          OutlinedButton(
            onPressed: !_ativa || _alterando ? null : _parar,
            child: const Text('Parar coleta'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => TelaLocalizacoes(
                  repositorio: widget.repositorio,
                  coletaAtiva: () => _ativa,
                ),
              ),
            ),
            child: const Text('Consultar histórico'),
          ),
          TextButton(
            onPressed: _alterando ? null : _abrirConfiguracoes,
            child: const Text('Configurações de permissão'),
          ),
          if (_alterando) const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}
