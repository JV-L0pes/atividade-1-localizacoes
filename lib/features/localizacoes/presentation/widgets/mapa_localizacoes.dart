import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/localizacao.dart';
import 'item_localizacao.dart';

class MapaLocalizacoes extends StatefulWidget {
  const MapaLocalizacoes({
    super.key,
    required this.localizacoes,
    this.tileProvider,
  });

  final List<Localizacao> localizacoes;
  final TileProvider? tileProvider;

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  final _controlador = MapController();
  late final TileProvider _provedor;
  bool _erroRuas = false;

  @override
  void initState() {
    super.initState();
    _provedor = widget.tileProvider ?? NetworkTileProvider();
  }

  List<LatLng> get _pontos =>
      widget.localizacoes.map((l) => LatLng(l.latitude, l.longitude)).toList();

  CameraFit? get _enquadramento {
    final limites = LatLngBounds.fromPoints(_pontos);
    if (limites.south == limites.north && limites.west == limites.east) {
      return null;
    }
    var sul = limites.south;
    var norte = limites.north;
    var oeste = limites.west;
    var leste = limites.east;
    if (sul == norte) {
      sul = (sul - 0.0001).clamp(-90, 90);
      norte = (norte + 0.0001).clamp(-90, 90);
    }
    if (oeste == leste) {
      oeste = (oeste - 0.0001).clamp(-180, 180);
      leste = (leste + 0.0001).clamp(-180, 180);
    }
    return CameraFit.bounds(
      bounds: LatLngBounds(LatLng(sul, oeste), LatLng(norte, leste)),
      padding: const EdgeInsets.all(48),
      maxZoom: 16,
    );
  }

  void _enquadrar() {
    final enquadramento = _enquadramento;
    if (enquadramento == null) {
      _controlador.move(_pontos.first, 16);
    } else {
      _controlador.fitCamera(enquadramento);
    }
  }

  void _avisarErroRuas() {
    if (_erroRuas || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_erroRuas) setState(() => _erroRuas = true);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _abrirAtribuicao() async {
    try {
      final abriu = await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
        mode: LaunchMode.externalApplication,
      );
      if (!abriu) throw Exception('Navegador indisponível.');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consulte a licença em openstreetmap.org/copyright.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pontos = _pontos;
    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(
            initialCenter: pontos.first,
            initialZoom: 16,
            initialCameraFit: _enquadramento,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.edu.fatec.localizacoes',
              tileProvider: _provedor,
              errorTileCallback: (tile, erro, pilha) => _avisarErroRuas(),
            ),
            MarkerLayer(
              markers: [
                for (var i = widget.localizacoes.length - 1; i >= 0; i--)
                  Marker(
                    point: pontos[i],
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: i == 0
                          ? 'Localização mais recente'
                          : 'Localização ${i + 1}',
                      icon: Icon(
                        Icons.location_on,
                        size: 36,
                        color: i == 0 ? Colors.red : Colors.blue.shade800,
                      ),
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => SafeArea(
                          child: SingleChildScrollView(
                            child: ItemLocalizacao(
                              localizacao: widget.localizacoes[i],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: null,
            onPressed: _enquadrar,
            tooltip: 'Enquadrar todos os pontos',
            child: const Icon(Icons.fit_screen),
          ),
        ),
        if (_erroRuas)
          Positioned(
            top: 12,
            left: 12,
            right: 72,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Não foi possível carregar as ruas. As posições continuam disponíveis.',
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: TextButton(
              onPressed: _abrirAtribuicao,
              child: const Text('© OpenStreetMap contributors'),
            ),
          ),
        ),
      ],
    );
  }
}
