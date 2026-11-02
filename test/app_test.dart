import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/app.dart';

void main() {
  testWidgets('oferece os cinco controles e navegação em português', (
    tester,
  ) async {
    await tester.pumpWidget(AppLocalizacoes());
    await tester.pumpAndSettle();
    for (final texto in [
      'Iniciar coleta',
      'Parar coleta',
      'Consultar histórico',
      'Ver mapa',
      'Configurações de permissão',
    ]) {
      expect(find.text(texto), findsOneWidget);
    }
    await tester.tap(find.text('Consultar histórico'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Voltar'), findsOneWidget);
  });
}
