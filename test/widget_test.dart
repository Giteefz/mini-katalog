import 'package:flutter_test/flutter_test.dart';
import 'package:mini_katalog/main.dart';

void main() {
  testWidgets('Mini Katalog ana ekranı açılır', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Mini Katalog'), findsOneWidget);
    expect(find.text('Sepet (0)'), findsOneWidget);
  });
}