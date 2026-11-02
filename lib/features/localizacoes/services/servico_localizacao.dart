import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/localizacao.dart';

class ServicoLocalizacao {
  Future<void> verificarPermissoes() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception(
        'Ative a localização (GPS) nas configurações do aparelho.',
      );
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão bloqueada. Use Configurações de permissão para habilitá-la.',
      );
    }
    if (permissao != LocationPermission.whileInUse &&
        permissao != LocationPermission.always) {
      throw Exception(
        'Permissão de localização negada. Tente iniciar novamente.',
      );
    }
    final notificacao = await Permission.notification.request();
    if (!notificacao.isGranted) {
      throw Exception(
        'Permita notificações nas configurações para manter a coleta visível.',
      );
    }
  }

  Stream<Localizacao> posicoes() =>
      Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 20),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Coleta de localizações ativa',
            notificationText:
                'Suas posições estão sendo salvas neste aparelho.',
            enableWakeLock: true,
          ),
        ),
      ).map(
        (posicao) => Localizacao(
          latitude: posicao.latitude,
          longitude: posicao.longitude,
          precisao: posicao.accuracy,
          instante: posicao.timestamp,
        ),
      );

  Future<bool> abrirConfiguracoes() => Geolocator.openAppSettings();
}
