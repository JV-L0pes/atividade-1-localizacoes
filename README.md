# Localizações

Atividade 1 — Coleta e visualização de localizações

Programação para Dispositivos Móveis I — Prof. Arley — Fatec

**Integrante: João Victor Lopes Rosa**

Aplicativo Flutter para Android com coleta contínua por stream, banco SQLite,
histórico e mapa interativo. Não utiliza backend.

## Executar

Ambiente utilizado: Flutter **3.47.8 stable**, Dart **3.13.7**.
É necessário ter o Android SDK configurado e um aparelho com depuração USB
ou emulador Android disponível (`flutter doctor` e `flutter devices`).

```sh
flutter pub get
flutter run
```

## Usar

1. Habilite a localização do aparelho e toque em **Iniciar coleta**.
2. Conceda acesso à localização durante o uso e permita notificações.
   Se houver bloqueio, utilize **Configurações de permissão**.
3. A coleta solicita alta precisão e intervalo de **20 segundos**, mantendo
   uma notificação visível. O sistema pode variar a frequência e a precisão.
4. Abra **Consultar histórico** ou **Ver mapa** sem parar a coleta.
   A coleta também continua ao minimizar o aplicativo enquanto o processo
   e o serviço em primeiro plano estiverem ativos.
5. Toque em **Parar coleta** para cancelar o stream e aguardar as gravações
   pendentes. Não há retomada automática após encerrar o processo ou reiniciar
   o aparelho.

O histórico mostra as últimas **100 posições**, da mais recente para a mais
antiga, com horário local, coordenadas com seis casas decimais e precisão em
metros com uma casa. **Atualizar** consulta os dados novamente.
**Limpar histórico** pede confirmação e exclui todas as posições, inclusive
as anteriores às 100 exibidas. Se a coleta estiver ativa, novos registros
continuarão sendo salvos.

O mapa mostra as últimas 100 posições, destaca a mais recente em vermelho e
permite tocar nos marcadores para consultar seus dados. Use **Atualizar** ou
**Enquadrar todos os pontos** quando necessário.

## Organização

Em `lib/features/localizacoes/`: `models/` representa os registros;
`data/database/` abre o banco; `data/repositories/` contém as operações de
persistência; `services/` cuida da localização e do cache; `presentation/`
contém as telas e os widgets. As telas não executam SQL.

São utilizados `geolocator`, `sqflite`, `flutter_map`, `latlong2`, `path`,
`path_provider`, `permission_handler` e `url_launcher`, além dos recursos do
SDK Flutter. `sqflite_common_ffi` é usado somente nos testes SQLite.

## Dados e mapa

- O banco privado `localizacoes.db` contém a tabela `localizacoes`: `id`,
  `latitude`, `longitude`, `precisao` e `instante`. Os instantes são gravados
  em UTC ISO 8601 e convertidos para horário local na tela.
- O limite de 100 só se aplica à consulta. Registros antigos permanecem no
  banco até a limpeza; limpar preserva a tabela e o arquivo do banco.
- As posições não são enviadas a um backend. O backup Android está desabilitado.
  Não publique bancos ou capturas com suas coordenadas pessoais.
- As ruas usam **© OpenStreetMap contributors**:
  [atribuição e licença](https://www.openstreetmap.org/copyright) e
  [política de tiles](https://operations.osmfoundation.org/policies/tiles/).
  As requisições de imagens revelam ao provedor o IP e a região do mapa exibida.
- O cache integrado respeita os cabeçalhos HTTP e usa uma pasta privada do app,
  com limite solicitado de 50 MB. A limpeza por tamanho é assíncrona e o Android
  pode remover o cache. Não há download em massa nem pré-carregamento offline;
  novas regiões precisam de internet. O histórico funciona sem internet.
- O ícone original está em `assets/icons/localizacoes.png`; as versões Android
  convencionais e adaptativa estão em `android/app/src/main/res/`.

## Verificar

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

O APK, quando gerado, fica em `build/app/outputs/flutter-apk/app-debug.apk`.
Os testes usam apenas posições sintéticas e bancos temporários, sem acessar os
servidores de tiles.

### Roteiro no Android

- Negar a permissão, negar permanentemente e tentar iniciar com o GPS desligado.
- Permitir localização e notificações; conferir a notificação durante a coleta.
- Tocar rapidamente em iniciar; navegar pelo histórico e mapa; minimizar por
  mais de 40 segundos e conferir os novos registros ao atualizar.
- Parar e verificar que nenhuma nova posição é salva; fechar e reabrir o app
  para conferir a persistência.
- Cancelar e confirmar a limpeza, inclusive com coleta ativa.
- Conferir os marcadores, os detalhes, o ponto vermelho, o enquadramento e a
  apresentação quando não há histórico ou acesso às ruas.
- Conferir o ícone na tela inicial e na lista de aplicativos após instalar.

**Validação pendente neste ambiente:** build e execução Android, coleta real
minimizada, notificação e ícone instalado. O Android SDK local está incompleto
e não havia aparelho ou emulador Android conectado durante o desenvolvimento.
