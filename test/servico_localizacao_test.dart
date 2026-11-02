import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localizacoes/features/localizacoes/services/servico_localizacao.dart';

class PlataformaLocalizacaoSimulada extends GeolocatorPlatform {
  bool gpsAtivo = true;
  LocationPermission permissao = LocationPermission.whileInUse;
  LocationPermission solicitada = LocationPermission.denied;
  LocationSettings? configuracao;

  @override
  Future<bool> isLocationServiceEnabled() async => gpsAtivo;

  @override
  Future<LocationPermission> checkPermission() async => permissao;

  @override
  Future<LocationPermission> requestPermission() async => solicitada;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    configuracao = locationSettings;
    return Stream.value(
      Position(
        latitude: 1,
        longitude: 2,
        accuracy: 3,
        timestamp: DateTime.utc(2026, 11, 2),
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('flutter.baseflow.com/permissions/methods');
  late GeolocatorPlatform anterior;
  late PlataformaLocalizacaoSimulada plataforma;
  var notificacaoPermitida = true;

  setUp(() {
    anterior = GeolocatorPlatform.instance;
    plataforma = PlataformaLocalizacaoSimulada();
    GeolocatorPlatform.instance = plataforma;
    notificacaoPermitida = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (chamada) async {
          expect(chamada.method, 'requestPermissions');
          expect(chamada.arguments, [17]);
          return {17: notificacaoPermitida ? 1 : 0};
        });
  });
  tearDown(() {
    GeolocatorPlatform.instance = anterior;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  test('GPS desligado orienta habilitar o serviço', () async {
    plataforma.gpsAtivo = false;
    await expectLater(
      ServicoLocalizacao().verificarPermissoes(),
      throwsA(predicate((erro) => erro.toString().contains('GPS'))),
    );
  });

  test('permissão negada não permite iniciar', () async {
    plataforma.permissao = LocationPermission.denied;
    await expectLater(
      ServicoLocalizacao().verificarPermissoes(),
      throwsA(predicate((erro) => erro.toString().contains('negada'))),
    );
  });

  test('permissão permanente negada orienta usar configurações', () async {
    plataforma.permissao = LocationPermission.deniedForever;
    await expectLater(
      ServicoLocalizacao().verificarPermissoes(),
      throwsA(predicate((erro) => erro.toString().contains('Configurações'))),
    );
  });

  test(
    'solicita a permissão ausente e aceita concessão durante o uso',
    () async {
      plataforma.permissao = LocationPermission.denied;
      plataforma.solicitada = LocationPermission.whileInUse;
      await ServicoLocalizacao().verificarPermissoes();
    },
  );

  test('notificação negada impede coleta sem aviso visível', () async {
    notificacaoPermitida = false;
    await expectLater(
      ServicoLocalizacao().verificarPermissoes(),
      throwsA(predicate((erro) => erro.toString().contains('notificações'))),
    );
  });

  test(
    'configura stream de alta precisão e notificação persistente própria',
    () async {
      final registro = await ServicoLocalizacao().posicoes().first;
      expect(registro.latitude, 1);
      expect(registro.longitude, 2);
      expect(registro.precisao, 3);
      expect(registro.instante, DateTime.utc(2026, 11, 2));
      final android = plataforma.configuracao! as AndroidSettings;
      expect(android.accuracy, LocationAccuracy.high);
      expect(android.distanceFilter, 0);
      expect(android.intervalDuration, const Duration(seconds: 20));
      expect(android.foregroundNotificationConfig!.enableWakeLock, isTrue);
      expect(android.foregroundNotificationConfig!.setOngoing, isTrue);
      expect(
        android.foregroundNotificationConfig!.notificationIcon.name,
        'ic_notificacao_localizacao',
      );
    },
  );
}
