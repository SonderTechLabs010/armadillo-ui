// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'now.dart';
import 'model.dart';
import 'peeking_overlay.dart';
import 'story_cluster_id.dart';
import 'story_list.dart';

export 'model.dart' show ScopedModel, Model, ScopedModelDecendant;

/// Tracks which story clusters are currently being dragged.  This is used by
/// some UI elements to scale ([StoryList]), fade out ([Now]), or slide away
/// ([PeekingOverlay]).
class StoryClusterDragStateModel extends Model {
  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static StoryClusterDragStateModel of(BuildContext context) =>
      new ModelFinder<StoryClusterDragStateModel>().of(context);

  final Set<StoryClusterId> _draggingStoryClusters = new Set<StoryClusterId>();
  final Set<StoryClusterId> _acceptableStoryClusters =
      new Set<StoryClusterId>();

  bool get isDragging => _draggingStoryClusters.isNotEmpty;
  bool get isAcceptable => _acceptableStoryClusters.isNotEmpty;

  void addDragging(StoryClusterId storyClusterId) {
    bool isDraggingBefore = isDragging;
    _draggingStoryClusters.add(storyClusterId);
    if (isDragging != isDraggingBefore) {
      notifyListeners();
    }
  }

  void removeDragging(StoryClusterId storyClusterId) {
    bool isDraggingBefore = isDragging;
    _draggingStoryClusters.remove(storyClusterId);
    if (isDragging != isDraggingBefore) {
      notifyListeners();
    }
  }

  void addAcceptance(StoryClusterId storyClusterId) {
    bool isAcceptableBefore = isAcceptable;
    _acceptableStoryClusters.add(storyClusterId);
    if (isAcceptable != isAcceptableBefore) {
      notifyListeners();
    }
  }

  void removeAcceptance(StoryClusterId storyClusterId) {
    bool isAcceptableBefore = isAcceptable;
    _acceptableStoryClusters.remove(storyClusterId);
    if (isAcceptable != isAcceptableBefore) {
      notifyListeners();
    }
  }
}
