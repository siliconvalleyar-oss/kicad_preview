import 'package:flutter_test/flutter_test.dart';
import 'package:kicad_preview/main.dart';

void main() {
  testWidgets('App should display splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KiCadPreviewApp());
    expect(find.text('KiCad Preview'), findsOneWidget);
  });
}
