// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:flux/email.dart';
import 'package:gallery/screens/email/editor.dart';
import 'package:gallery/screens/email/inbox.dart';
import 'package:gallery/screens/email/menu.dart';
import 'package:gallery/screens/email/thread.dart';
import 'package:models/email.dart';
import 'story.dart';

void _createMockEmailThreads() {
  kEmailActions.updateThreads(<Thread>[
    new MockThread(id: 'thread01'),
    new MockThread(id: 'thread02'),
    new MockThread(id: 'thread03'),
  ]);
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
    case 'email/editor':
      return new EmailEditorScreen();
    case 'email/inbox':
      _createMockEmailThreads();
      return new EmailListScreen();
    case 'email/menu':
      return new EmailNavScreen();
    case 'email/thread':
      _createMockEmailThreads();
      return new EmailThreadScreen(threadId: 'thread01');
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
