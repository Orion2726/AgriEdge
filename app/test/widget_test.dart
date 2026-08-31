import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agriedge/app.dart';

void main() {
  testWidgets('App boots to the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgriEdgeApp()));
    await tester.pump();

    expect(find.text('AgriEdge'), findsOneWidget);
    expect(find.text('Market Price'), findsOneWidget);
  });
}
