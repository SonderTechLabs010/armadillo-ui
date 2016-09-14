// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import '../lib/now_minimized_info_fader.dart';

const int _kStoryCount = 4;
const double _kRecentListWidthSingleColumn = 500.0;
const double _kRecentListHorizontalMarginsSingleColumn = 16.0;
const double _kRecentListWidthMultiColumn = 700.0;
const double _kRecentListHeight = 600.0;
const double _kStoryBarMaximizedHeight = 48.0;

void main() {
  testWidgets('Initial opacity is 0.0.', (WidgetTester tester) async {
    NowMinimizedInfoFader fader = new NowMinimizedInfoFader();
    expect(fader.opacity, 0.0);
  });

  testWidgets('Forcing fade in turns opacity to 1.0 instantly.',
      (WidgetTester tester) async {
    bool changed = false;
    NowMinimizedInfoFader fader = new NowMinimizedInfoFader(
      onChange: () {
        changed = true;
      },
    );
    expect(fader.opacity, 0.0);
    fader.fadeIn(force: true);
    expect(fader.opacity, 1.0);
    expect(changed, false);
    await tester.pump();
    expect(changed, true);
    fader.reset();
  });

  testWidgets(
      'Not forcing fade in starts opacity as 0.0 and gradually goes to 1.0.',
      (WidgetTester tester) async {
    bool changed = false;
    NowMinimizedInfoFader fader = new NowMinimizedInfoFader(
      onChange: () {
        changed = true;
      },
    );
    expect(fader.opacity, 0.0);
    fader.fadeIn();
    expect(fader.opacity, 0.0);
    expect(changed, false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(changed, true);
    changed = false;
    expect(fader.opacity, lessThan(1.0));
    expect(fader.opacity, greaterThan(0.0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(changed, true);
    expect(fader.opacity, 1.0);
    fader.reset();
  });

  testWidgets('We start fading out a short time after fading in.',
      (WidgetTester tester) async {
    bool changed = false;
    NowMinimizedInfoFader fader = new NowMinimizedInfoFader(
      onChange: () {
        changed = true;
      },
    );
    expect(fader.opacity, 0.0);
    fader.fadeIn();
    expect(fader.opacity, 0.0);
    expect(changed, false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(changed, true);
    changed = false;
    expect(fader.opacity, lessThan(1.0));
    expect(fader.opacity, greaterThan(0.0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(changed, true);
    changed = false;
    expect(fader.opacity, 1.0);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(changed, true);
    changed = false;
    expect(fader.opacity, lessThan(1.0));
    expect(fader.opacity, greaterThan(0.0));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(changed, true);
    expect(fader.opacity, 0.0);
    fader.reset();
  });
}
