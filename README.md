# Localizações

Atividade 1 — Coleta e visualização de localizações
Programação para Dispositivos Móveis I — Prof. Arley — Fatec

**Integrante: João Victor Lopes Rosa**

Aplicativo Flutter para Android que coleta posições por stream, salva em SQLite
e exibe histórico e mapa. Não usa backend.

## Executar

Requisitos: Flutter 3.47.8 e Android SDK (API 36).

```sh
flutter pub get
flutter run
flutter build apk --debug
```

O APK fica em `build/app/outputs/flutter-apk/app-debug.apk`.

## Uso

1. Toque em **Iniciar coleta** e permita localização e notificações.
2. A coleta usa alta precisão e intervalo solicitado de 20 segundos, com
   notificação visível. Continua ao minimizar o app enquanto o serviço estiver
   ativo; não retoma após encerrar o processo.
3. **Parar coleta** cancela o stream e aguarda as gravações pendentes.
4. **Consultar histórico** mostra as últimas 100 posições com horário local,
   coordenadas e precisão. **Limpar histórico** apaga tudo após confirmação.
5. **Ver mapa** mostra as posições, com a mais recente em vermelho; toque em um
   marcador para ver os detalhes.

## Dados e mapa

- Banco privado `localizacoes.db`, instantes em UTC ISO 8601. Nada é enviado a
  backend; o backup Android está desabilitado. Não publique o banco nem
  capturas com coordenadas.
- Ruas de **© [OpenStreetMap contributors](https://www.openstreetmap.org/copyright)**,
  com cache privado e sem download em massa. O histórico funciona offline; o
  mapa precisa de internet.

O código está em `lib/features/localizacoes/` (`models`, `data`, `services`,
`presentation`), seguindo a estrutura pedida na atividade.

## Verificar

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

**48 testes** e `flutter analyze` sem problemas. Testado em moto g86 5G
(Android 16): permissões, notificação, coleta, minimização, parada, histórico,
mapa, limpeza e persistência.
