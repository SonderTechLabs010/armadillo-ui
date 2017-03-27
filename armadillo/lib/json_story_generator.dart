// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'story.dart';
import 'story_builder.dart';
import 'story_cluster.dart';
import 'story_generator.dart';

const String _kJsonUrl = 'packages/armadillo/res/stories.json';

/// Creates stories from a JSON file.
class JsonStoryGenerator extends StoryGenerator {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();
  List<StoryCluster> _storyClusters = <StoryCluster>[];

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  List<StoryCluster> get storyClusters => _storyClusters;

  /// Loads stories from the JSON file [_kJsonUrl] contained in [assetBundle].
  void load(AssetBundle assetBundle) {
    assetBundle.loadString(_kJsonUrl).then((String json) {
      final Map<String, List<Map<String, Object>>> decodedJson =
          convert.JSON.decode(json);

      // Load stories
      _storyClusters = decodedJson["stories"]
          .map((Map<String, Object> story) => new StoryCluster(stories: <Story>[
                storyBuilder(story),
              ]))
          .toList();
      _notifyListeners();
    });
  }

  void _notifyListeners() {
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }
}
