// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_flutter/quarterback.dart';
import 'package:email_session_store/email_session_store_mock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'story.dart';

void _createMockEmailSessionStore() {
  kEmailSessionStoreToken ??= new StoreToken(new EmailSessionStoreMock());
}

Widget _widgetBuilder(String module, Map<String, Object> state) {
  switch (module) {
    case 'image':
      return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            new Image.asset(
              (constraints.maxWidth > constraints.maxHeight)
                  ? state['imageWide'] ?? state['image']
                  : state['image'],
              alignment: FractionalOffset.topCenter,
              fit: ImageFit.cover,
            ),
      );
    case 'email/quarterback':
      _createMockEmailSessionStore();
      return new EmailQuarterbackModule();
    default:
      return new Center(child: new Text('BAD MODULE!!!'));
  }
}

/// Construct a story object from a decoded json story config.
Story storyBuilder(Map<String, Object> story) {
  return new Story(
    id: new StoryId(story['id']),
    builder: (_) => new ScrollConfiguration(
          child: _widgetBuilder(story['module'], story['state']),
        ),
    title: story['title'],
    icons: (story['icons'] as List<String>)
        .map(
          (String icon) =>
              (BuildContext context, double opacity) => new Image.asset(
                    icon,
                    fit: ImageFit.cover,
                    color: Colors.white.withOpacity(opacity),
                  ),
        )
        .toList(),
    avatar: (_, double opacity) => new Opacity(
          opacity: opacity,
          child: new Image.asset(
            story['avatar'],
            fit: ImageFit.cover,
          ),
        ),
    lastInteraction: new DateTime.now().subtract(
      new Duration(
        seconds: int.parse(story['lastInteraction']),
      ),
    ),
    cumulativeInteractionDuration: new Duration(
      minutes: int.parse(story['culmulativeInteraction']),
    ),
    themeColor: new Color(int.parse(story['color'])),
    inactive: 'true' == (story['inactive'] ?? 'false'),
  );
}
