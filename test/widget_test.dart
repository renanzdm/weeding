import 'package:flutter_test/flutter_test.dart';

import 'package:fotos_casamemento_app/main.dart';

void main() {
  testWidgets('exibe o convite para compartilhar fotos',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CasamentoApp());

    expect(find.text('Ajude a contar\na nossa história.'), findsOneWidget);
    expect(find.text('Compartilhe suas fotos'), findsOneWidget);
    expect(find.text('Escolher fotos'), findsOneWidget);
  });
}
