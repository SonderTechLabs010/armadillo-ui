// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:apps.modular.services.story/story_provider.fidl.dart';

const List<String> _kStoryUrls = const <String>[
  'file:///system/apps/color',
  'file:///system/apps/moterm',
  'file:///system/apps/spinning_square_view',
  'file:///system/apps/paint_view',
];

const Map<String, String> _kStoryColors = const <String, String>{
  'file:///system/apps/color': '0xFF5AFFD6',
  'file:///system/apps/moterm': '0xFF212121',
  'file:///system/apps/spinning_square_view': '0xFF512DA8',
  'file:///system/apps/paint_view': '0xFFAD1457',
};

Map<String, dynamic> _kStoryRootDocs = <String, dynamic>{
  'file:///system/apps/color': <String, String>{'color': '0xFF1DE9B6'},
};

/// Creates the initial list of stories to be shown when no stories exist.
class InitialStoryGenerator {
  InitialStoryGenerator._internal();

  static void createStories(StoryProviderProxy storyProvider) {
    _kStoryUrls.forEach((String storyUrl) {
      storyProvider.createStoryWithInfo(
        storyUrl,
        <String, String>{'color': _kStoryColors[storyUrl]},
        JSON.encode(_kStoryRootDocs[storyUrl] ?? null),
        (String storyId) => null,
      );
    });
  }
}
