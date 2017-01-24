// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'config_manager.dart';
import 'story_cluster.dart';

export 'config_manager.dart' show ScopedModel, Model;

/// Tracks which story clusters are currently being dragged.  This is used by
/// some UI elements to scale ([StoryList]), fade out ([Now]), or slide away
/// ([SuggestionOverlay]).
class StoryClusterDragStateModel extends Model {
  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static StoryClusterDragStateModel of(BuildContext context,
          {bool rebuildOnChange: false}) =>
      new ModelFinder<StoryClusterDragStateModel>()
          .of(context, rebuildOnChange: rebuildOnChange);

  final Set<StoryCluster> _draggingStoryClusters = new Set<StoryCluster>();

  bool get areStoryClustersDragging => _draggingStoryClusters.isNotEmpty;

  void addDraggingStoryCluster(StoryCluster storyCluster) {
    _draggingStoryClusters.add(storyCluster);
    notifyListeners();
  }

  void removeDraggingStoryCluster(StoryCluster storyCluster) {
    _draggingStoryClusters.remove(storyCluster);
    notifyListeners();
  }
}
