// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';
import 'panel_drag_targets.dart';
import 'simulated_fractional.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_panels.dart';

/// A [Story] with no content.  This is used in place of a real story within a
/// [StoryCluster] to take up empty visual space in [StoryPanels] when
/// [PanelDragTargets] has a hovering cluster (ie. we're previewing the
/// combining of two clusters).
class PlaceHolderStory extends Story {
  final StoryId associatedStoryId;

  PlaceHolderStory({
    this.associatedStoryId,
    Panel panel,
    GlobalKey<SimulatedFractionalState> positionedKey,
  })
      : super(
          id: new StoryId('PlaceHolder $associatedStoryId'),
          panel: panel,
          positionedKey: positionedKey,
          builder: (_) => new Container(
                decoration: new BoxDecoration(
                  backgroundColor: new Color(0xFFE6E6E6).withOpacity(0.25),
                ),
              ),
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
        panel: panel ?? this.panel,
        associatedStoryId: this.associatedStoryId,
        positionedKey: positionedKey ?? this.positionedKey,
      );
}
