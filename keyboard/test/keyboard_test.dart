// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter/widgets.dart';

import '../lib/keyboard.dart';

final services.AssetBundle _defaultBundle =
    new services.NetworkAssetBundle(Uri.base);

void main() {
  testWidgets('tapping "uppercase" symbol swaps to upper case letters',
      (WidgetTester tester) async {
    String onTextText;

    Keyboard keyboard = new Keyboard(
        key: new GlobalKey(),
        onText: (String text) {
          onTextText = text;
        },
        onSuggestion: (String suggestion) {},
        onDelete: () {},
        onGo: () {});
    GlobalKey keyboardKey = keyboard.key;

    await tester.pumpWidget(new DefaultAssetBundle(
        bundle: _defaultBundle, child: new Center(child: keyboard)));
    expect(onTextText, isNull);

    // tap the center of the keyboard to get a lower case letter
    await _tap(tester, _getCenter(tester, keyboardKey));
    expect(onTextText, isNotNull);
    String testOnTextText = onTextText;

    // tap the shift key to switch the keyboard into the uppercase state
    await _tap(tester, _getShiftPosition(tester, keyboardKey));
    expect(onTextText, testOnTextText);

    // tap the center of the keyboard to get an upper case version of
    // the lower case letter obtained earlier.
    await _tap(tester, _getCenter(tester, keyboardKey));
    expect(onTextText, testOnTextText.toUpperCase());
  });
}

Point _getShiftPosition(WidgetTester tester, Key keyboardKey) {
  final element = find.byKey(keyboardKey);
  Point topLeft = tester.getTopLeft(element);
  Point bottomLeft = tester.getBottomLeft(element);
  return new Point(topLeft.x, topLeft.y + ((bottomLeft.y - topLeft.y) * 0.6));
}

Point _getCenter(WidgetTester tester, Key key) =>
    tester.getCenter(find.byKey(key));

_tap(WidgetTester tester, Point point) async {
  TestGesture gesture = await tester.startGesture(point, pointer: 8);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}
