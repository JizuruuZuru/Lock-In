import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:benchmark/main.dart';

void main() {
  testWidgets('BrainTrainerApp is available', (WidgetTester tester) async {
    expect(const BrainTrainerApp(), isA<StatefulWidget>());
  });
}
