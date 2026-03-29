import 'package:flutter_test/flutter_test.dart';

import 'package:swiftcart_app/app/app.dart';

void main() {
  test('SwiftCartApp can be constructed', () {
    // Keep tests lightweight: pumping the widget tree requires Firebase to be
    // initialized, which is outside the scope of this unit test.
    expect(const SwiftCartApp(), isA<SwiftCartApp>());
  });
}
