import 'package:flutter_test/flutter_test.dart';
import 'package:movie_app/main.dart';

void main() {
  testWidgets('Movie App starts successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MovieApp());

    expect(find.text('Movie App'), findsOneWidget);
  });
}