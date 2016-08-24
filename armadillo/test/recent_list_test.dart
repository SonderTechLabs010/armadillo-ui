// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../lib/recent_list.dart';

const int _kStoryCount = 4;
const double _kRecentListWidthSingleColumn = 500.0;
const double _kRecentListHorizontalMarginsSingleColumn = 16.0;
const double _kRecentListWidthMultiColumn = 700.0;

void main() {
  testWidgets('Single Column RecentList children extend to fit parent',
      (WidgetTester tester) async {
    GlobalKey recentListKey = new GlobalKey();

    List<GlobalKey> storyKeys =
        new List<GlobalKey>.generate(4, (int index) => new GlobalKey());

    RecentList recentList = new RecentList(
        key: recentListKey,
        stories: new List<Story>.generate(
            storyKeys.length,
            (int index) => new Story(
                builder: (_) => new Container(key: storyKeys[index]),
                lastInteraction: new DateTime.now(),
                cumulativeInteractionDuration: const Duration(minutes: 5))));

    await tester.pumpWidget(new Center(
        child: new Container(
            width: _kRecentListWidthSingleColumn, child: recentList)));
    expect(find.byKey(recentListKey), isNotNull);
    expect(tester.getSize(find.byKey(recentListKey)).width,
        _kRecentListWidthSingleColumn);
    storyKeys.forEach((GlobalKey key) {
      final finder = find.byKey(key);
      expect(finder, isNotNull);
      final size = tester.getSize(finder);
      expect(
          size.width,
          _kRecentListWidthSingleColumn -
              _kRecentListHorizontalMarginsSingleColumn);
    });
  });

  testWidgets(
      'Multicolumn RecentList children do not extend to fit parent and are instead 16/9 aspect ratio',
      (WidgetTester tester) async {
    GlobalKey recentListKey = new GlobalKey();

    List<GlobalKey> storyKeys =
        new List<GlobalKey>.generate(4, (int index) => new GlobalKey());

    RecentList recentList = new RecentList(
        key: recentListKey,
        stories: new List<Story>.generate(
            storyKeys.length,
            (int index) => new Story(
                builder: (_) => new Container(key: storyKeys[index]),
                lastInteraction: new DateTime.now(),
                cumulativeInteractionDuration: const Duration(minutes: 5))));

    await tester.pumpWidget(new Center(
        child: new Container(
            width: _kRecentListWidthMultiColumn, child: recentList)));
    expect(find.byKey(recentListKey), isNotNull);
    expect(tester.getSize(find.byKey(recentListKey)).width,
        _kRecentListWidthMultiColumn);
    storyKeys.forEach((GlobalKey key) {
      final finder = find.byKey(key);
      expect(finder, isNotNull);
      final size = tester.getSize(finder);
      expect(size.width / size.height, 16.0 / 9.0);
    });
  });
}
