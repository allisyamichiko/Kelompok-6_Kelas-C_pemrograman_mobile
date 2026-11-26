import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamly_flutter/main.dart';

void main() {
  testWidgets('TeamlyApp renders welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TeamlyApp()));
    expect(find.text('Teamly'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
