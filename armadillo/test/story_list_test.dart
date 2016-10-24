// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/delegating_page_route.dart';

import '../lib/story.dart';
import '../lib/story_cluster.dart';
import '../lib/story_list.dart';
import '../lib/story_manager.dart';

const int _kStoryCount = 4;
const double _kWidthSingleColumn = 500.0;
const double _kHorizontalMarginsSingleColumn = 16.0;
const double _kWidthMultiColumn = 700.0;
const double _kHeight = 600.0;
const double _kStoryBarMaximizedHeight = 48.0;

void main() {
  testWidgets('Single Column StoryList children extend to fit parent',
      (WidgetTester tester) async {
    GlobalKey storyListKey = new GlobalKey();
    GlobalKey scrollableKey = new GlobalKey();

    List<GlobalKey> storyKeys =
        new List<GlobalKey>.generate(4, (int index) => new GlobalKey());

    StoryList storyList = new StoryList(
      key: storyListKey,
      scrollableKey: scrollableKey,
      multiColumn: false,
      quickSettingsHeightBump: 200.0,
      parentSize: new Size(
        _kWidthSingleColumn,
        _kHeight,
      ),
    );
    StoryManager storyManager = new DummyStoryManager(storyKeys: storyKeys);
    await tester.pumpWidget(
      _wrapWithWidgetsApp(
        child: new InheritedStoryManager(
          storyManager: storyManager,
          child: new Center(
            child: new Container(width: _kWidthSingleColumn, child: storyList),
          ),
        ),
      ),
    );
    expect(find.byKey(storyListKey), isNotNull);
    expect(
      tester.getSize(find.byKey(storyListKey)).width,
      _kWidthSingleColumn,
    );
    storyKeys.forEach((GlobalKey key) {
      final finder = find.byKey(key);
      expect(finder, isNotNull);
      final size = tester.getSize(finder);
      expect(size.width, _kWidthSingleColumn);
    });
  });

  testWidgets(
      'Multicolumn StoryList children do not extend to fit parent and are instead 16/9 aspect ratio',
      (WidgetTester tester) async {
    GlobalKey storyListKey = new GlobalKey();
    GlobalKey scrollableKey = new GlobalKey();

    List<GlobalKey> storyKeys =
        new List<GlobalKey>.generate(4, (int index) => new GlobalKey());

    StoryList storyList = new StoryList(
      key: storyListKey,
      scrollableKey: scrollableKey,
      multiColumn: true,
      quickSettingsHeightBump: 200.0,
      parentSize: new Size(
        _kWidthMultiColumn,
        _kHeight,
      ),
    );
    StoryManager storyManager = new DummyStoryManager(storyKeys: storyKeys);

    await tester.pumpWidget(
      _wrapWithWidgetsApp(
        child: new InheritedStoryManager(
          storyManager: storyManager,
          child: new Center(
            child: new Container(
              width: _kWidthMultiColumn,
              child: storyList,
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(storyListKey), isNotNull);
    expect(
      tester.getSize(find.byKey(storyListKey)).width,
      _kWidthMultiColumn,
    );
    storyKeys.forEach((GlobalKey key) {
      final finder = find.byKey(key);
      expect(finder, isNotNull);
      final size = tester.getSize(finder);
      expect(size.width, _kWidthMultiColumn);
      expect(size.height, _kHeight - _kStoryBarMaximizedHeight);
    });
  });
}

class DummyStoryManager extends StoryManager {
  final List<GlobalKey> storyKeys;

  DummyStoryManager({this.storyKeys}) : super();

  @override
  List<StoryCluster> get storyClusters => new List<StoryCluster>.generate(
        storyKeys.length,
        (int index) => new StoryCluster(
              stories: [
                new Story(
                  id: new StoryId(storyKeys[index]),
                  builder: (_) => new Container(key: storyKeys[index]),
                  title: '',
                  avatar: (_) => new Container(),
                  lastInteraction: new DateTime.now(),
                  cumulativeInteractionDuration: const Duration(minutes: 5),
                  themeColor: new Color(0xFFFFFFFF),
                ),
              ],
            ),
      );
}

Widget _wrapWithWidgetsApp({Widget child}) => new WidgetsApp(
      title: '',
      color: const Color(0xFFFFFFFF),
      onGenerateRoute: (RouteSettings settings) => new DelegatingPageRoute(
            (_) => child,
            settings: settings,
          ),
    );
