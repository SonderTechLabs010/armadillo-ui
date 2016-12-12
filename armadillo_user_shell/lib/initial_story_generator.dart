// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.document_store/document.fidl.dart';
import 'package:apps.modular.services.user/story_provider.fidl.dart';

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

final Map<String, Map<String, Document>> _kStoryRootDocs = {
  'file:///system/apps/color': {
    'color': new Document()
      ..docid = 'color'
      ..properties = <String, Value>{
        'color': new Value()..stringValue = '0xFF1DE9B6'
      },
  },
};

/// Creates the initial list of stories to be shown when no stories exist.
class InitialStoryGenerator {
  InitialStoryGenerator._internal();

  static void createStories(StoryProviderProxy storyProvider) {
    _kStoryUrls.forEach((String storyUrl) {
      storyProvider.createStoryWithInfo(
        storyUrl,
        <String, String>{'color': _kStoryColors[storyUrl]},
        _kStoryRootDocs[storyUrl] ?? <String, Document>{},
        (String storyId) => null,
      );
    });
  }
}
