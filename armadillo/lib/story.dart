// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';

/// The representation of a Story.  A Story's contents are display as a [Widget]
/// provided by [builder] while the size of a story in the [RecentList] is
/// determined by [lastInteraction] and [cumulativeInteractionDuration].
class Story {
  final Object id;
  final WidgetBuilder builder;
  final List<WidgetBuilder> icons;
  final WidgetBuilder avatar;
  final String title;
  final DateTime lastInteraction;
  final Duration cumulativeInteractionDuration;
  final Color themeColor;
  final bool inactive;
  final Object storyBarKeyObject;
  final Object clusterId;
  final Object clusterDraggableId;
  final Panel panel;

  Story({
    this.id,
    this.builder,
    this.title: '',
    this.icons: const <WidgetBuilder>[],
    this.avatar,
    this.lastInteraction,
    this.cumulativeInteractionDuration,
    this.themeColor,
    this.inactive: false,
    Object storyBarKeyObject,
    Object clusterId,
    Object clusterDraggableId,
    Panel panel,
  })
      : this.storyBarKeyObject = storyBarKeyObject ?? new Object(),
        this.clusterId = clusterId ?? new Object(),
        this.clusterDraggableId = clusterDraggableId ?? new Object(),
        this.panel = panel ?? new Panel();

  Story copyWith({
    DateTime lastInteraction,
    Duration cumulativeInteractionDuration,
    bool inactive,
    Panel panel,
    Object clusterDraggableId,
  }) =>
      new Story(
        id: this.id,
        builder: this.builder,
        lastInteraction: lastInteraction ?? this.lastInteraction,
        cumulativeInteractionDuration:
            cumulativeInteractionDuration ?? this.cumulativeInteractionDuration,
        themeColor: this.themeColor,
        icons: new List.from(this.icons),
        avatar: this.avatar,
        title: this.title,
        inactive: inactive ?? this.inactive,
        storyBarKeyObject: this.storyBarKeyObject,
        clusterId: this.clusterId,
        clusterDraggableId: this.clusterDraggableId,
        panel: panel ?? this.panel,
      );

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) => (other is Story && other.id == id);

  @override
  String toString() => 'Story( id: $id, title: $title, panel: $panel )';

  static int storyListHashCode(List<Story> stories) =>
      hashList(stories.map((Story s) => s.id));
}
