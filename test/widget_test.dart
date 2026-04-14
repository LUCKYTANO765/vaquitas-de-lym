import 'package:flutter_test/flutter_test.dart';
import 'package:vaquitas_de_lym/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VaquitasApp());
    expect(find.byType(VaquitasApp), findsOneWidget);
  });
}
