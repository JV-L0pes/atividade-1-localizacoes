import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/localizacoes/data/database/banco_localizacoes.dart';
import 'features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'features/localizacoes/presentation/screens/tela_coleta.dart';
import 'features/localizacoes/services/servico_localizacao.dart';

class AppLocalizacoes extends StatelessWidget {
  AppLocalizacoes({super.key});

  final _repositorio = RepositorioLocalizacoes(BancoLocalizacoes());
  final _servico = ServicoLocalizacao();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Localizações',
    debugShowCheckedModeBanner: false,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(colorSchemeSeed: const Color(0xFF173D55)),
    home: TelaColeta(repositorio: _repositorio, servico: _servico),
  );
}
