import 'package:flutter/material.dart';

import '../../models/localizacao.dart';

class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({super.key, required this.localizacao});

  final Localizacao localizacao;

  @override
  Widget build(BuildContext context) {
    final instante = localizacao.instante.toLocal();
    String dois(int valor) => valor.toString().padLeft(2, '0');
    final data =
        '${dois(instante.day)}/${dois(instante.month)}/${instante.year}';
    final hora =
        '${dois(instante.hour)}:${dois(instante.minute)}:${dois(instante.second)}';
    return ListTile(
      title: Text('$data $hora'),
      subtitle: Text(
        'Latitude: ${localizacao.latitude.toStringAsFixed(6)}\n'
        'Longitude: ${localizacao.longitude.toStringAsFixed(6)}\n'
        'Precisão: ${localizacao.precisao.toStringAsFixed(1)} m',
      ),
      isThreeLine: true,
    );
  }
}
