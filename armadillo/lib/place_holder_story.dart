// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';
import 'panel_drag_targets.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_panels.dart';

/// A [Story] with no content.  This is used in place of a real story within a
/// [StoryCluster] to take up empty visual space in [StoryPanels] when
/// [PanelDragTargets] has a hovering cluster (ie. we're previewing the
/// combining of two clusters).
class PlaceHolderStory extends Story {
  final StoryId associatedStoryId;
  final int _index;

  PlaceHolderStory({int index, this.associatedStoryId, Panel panel})
      : _index = index,
        super(
          id: new StoryId('PlaceHolder $index'),
          panel: panel,
          builder: (_) => new Container(),
        );

  @override
  bool get isPlaceHolder => true;

  @override
  Story copyWith({
    DateTime lastInteraction,
    Duration cumulativeInteractionDuration,
    bool inactive,
    Panel panel,
    GlobalKey clusterDraggableKey,
    GlobalKey positionedKey,
  }) =>
      new PlaceHolderStory(
        index: this._index,
        panel: panel ?? this.panel,
        associatedStoryId: this.associatedStoryId,
      );
}
