// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';
import 'story.dart';

/// A [Story] with no content.  This is used in place of a real story within a
/// [StoryCluster] to take up empty visual space in [StoryPanels] when
/// [PanelDragTargets] has a hovering cluster (ie. we're previewing the
/// combining of two clusters).
class PlaceHolderStory extends Story {
  PlaceHolderStory({Object id, Panel panel})
      : super(
            id: id ?? new Object(),
            panel: panel,
            builder: (_) => new Container());

  @override
  bool get isPlaceHolder => true;

  @override
  Story copyWith({
    DateTime lastInteraction,
    Duration cumulativeInteractionDuration,
    bool inactive,
    Panel panel,
    Object clusterDraggableId,
  }) =>
      new PlaceHolderStory(id: this.id, panel: panel ?? this.panel);
}
