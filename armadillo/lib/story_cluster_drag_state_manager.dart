// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'config_manager.dart';
import 'story_cluster.dart';

/// Tracks which story clusters are currently being dragged.  This is used by
/// some UI elements to scale ([StoryList]), fade out ([Now]), or slide away
/// ([SuggestionOverlay]).
class StoryClusterDragStateManager extends ConfigManager {
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

class InheritedStoryClusterDragStateManager extends StatelessWidget {
  final StoryClusterDragStateManager storyClusterDragStateManager;
  final Widget child;

  InheritedStoryClusterDragStateManager({
    this.storyClusterDragStateManager,
    this.child,
  });

  @override
  Widget build(BuildContext context) => new InheritedConfigManagerWidget(
        configManager: storyClusterDragStateManager,
        builder: (BuildContext context) =>
            new _InheritedStoryClusterDragStateManager(
              storyClusterDragStateManager: storyClusterDragStateManager,
              child: child,
            ),
      );

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [_InheritedStoryManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  /// If [rebuildOnChange] is true, the caller will be rebuilt upon changes
  /// to [StoryClusterDragStateManager].
  static StoryClusterDragStateManager of(
    BuildContext context, {
    bool rebuildOnChange: false,
  }) {
    _InheritedStoryClusterDragStateManager
        inheritedStoryClusterDragStateManager = rebuildOnChange
            ? context.inheritFromWidgetOfExactType(
                _InheritedStoryClusterDragStateManager)
            : context.ancestorWidgetOfExactType(
                _InheritedStoryClusterDragStateManager);
    return inheritedStoryClusterDragStateManager?.configManager;
  }
}

class _InheritedStoryClusterDragStateManager extends InheritedConfigManager {
  _InheritedStoryClusterDragStateManager({
    Widget child,
    StoryClusterDragStateManager storyClusterDragStateManager,
  })
      : super(child: child, configManager: storyClusterDragStateManager);
}
