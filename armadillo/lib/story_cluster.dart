// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'panel.dart';
import 'story.dart';

class StoryCluster {
  final Object id;
  final DateTime lastInteraction;
  final Duration cumulativeInteractionDuration;
  final List<Story> stories;
  final String title;
  final Object carouselId;
  final Object clusterDraggableId;
  final Object clusterDragTargetsId;

  StoryCluster({
    Object id,
    Object carouselId,
    Object clusterDraggableId,
    Object clusterDragTargetsId,
    List<Story> stories,
  })
      : this.stories = stories,
        this.title = _getClusterTitle(stories),
        this.lastInteraction = _getClusterLastInteraction(stories),
        this.cumulativeInteractionDuration =
            _getClusterCumulativeInteractionDuration(stories),
        this.id = id ?? new Object(),
        this.carouselId = carouselId ?? new Object(),
        this.clusterDraggableId = clusterDraggableId ?? new Object(),
        this.clusterDragTargetsId = clusterDragTargetsId ?? new Object();

  factory StoryCluster.fromStory(Story story) {
    return new StoryCluster(
      id: story.clusterId,
      clusterDraggableId: story.clusterDraggableId,
      stories: [story.copyWith(panel: new Panel())],
    );
  }

  StoryCluster copyWith({
    DateTime lastInteraction,
    Duration cumulativeInteractionDuration,
    bool inactive,
    Object clusterDraggableId,
  }) =>
      new StoryCluster(
        id: this.id,
        carouselId: this.carouselId,
        clusterDraggableId: clusterDraggableId ?? this.clusterDraggableId,
        clusterDragTargetsId: this.clusterDragTargetsId,
        stories: new List<Story>.generate(
          stories.length,
          (int index) => stories[index].copyWith(
                lastInteraction: lastInteraction,
                cumulativeInteractionDuration: cumulativeInteractionDuration,
                inactive: inactive,
              ),
        ),
      );

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) => (other is StoryCluster && other.id == id);

  @override
  String toString() {
    String string = 'StoryCluster( id: $id, title: $title,\n';
    stories.forEach((Story story) {
      string += '\n   story: $story';
    });
    string += ' )';
    return string;
  }

  /// Returns the [Panel]s of the [stories].
  Iterable<Panel> get panels => stories.map((Story story) => story.panel);

  /// Resizes the [Panel]s of the [stories] to have columns with equal widths
  /// and rows of equal heights.
  void normalizeSizes() {
    Set<double> currentLeftsSet = new Set<double>();
    Set<double> currentTopsSet = new Set<double>();
    panels.forEach((Panel panel) {
      currentLeftsSet.add(panel.left);
      currentTopsSet.add(panel.top);
    });

    List<double> currentSortedLefts = new List<double>.from(currentLeftsSet);
    currentSortedLefts.sort();

    List<double> currentSortedTops = new List<double>.from(currentTopsSet);
    currentSortedTops.sort();

    Map<double, double> leftMap = <double, double>{1.0: 1.0};
    double left = 0.0;
    for (int i = 0; i < currentSortedLefts.length; i++) {
      leftMap[currentSortedLefts[i]] = left;
      left += getSpanSpan(1.0, i, currentSortedLefts.length);
    }

    Map<double, double> topMap = <double, double>{1.0: 1.0};
    double top = 0.0;
    for (int i = 0; i < currentSortedTops.length; i++) {
      topMap[currentSortedTops[i]] = top;
      top += getSpanSpan(1.0, i, currentSortedTops.length);
    }

    panels.toList().forEach(
          (Panel panel) => replace(
                panel: panel,
                withPanel: new Panel.fromLTRB(
                  leftMap[panel.left],
                  topMap[panel.top],
                  leftMap[panel.right],
                  topMap[panel.bottom],
                ),
              ),
        );
  }

  /// Adds the [story] to [stories] with a [Panel] of [withPanel].
  void add({Story story, Panel withPanel}) {
    stories.add(story.copyWith(panel: withPanel));
  }

  /// Replaces the [Story.panel] of the story with [panel] with [withPanel]/
  void replace({Panel panel, Panel withPanel}) {
    Story story = stories.where((Story story) => story.panel == panel).single;
    stories.remove(story);
    stories.add(story.copyWith(panel: withPanel));
  }

  static String _getClusterTitle(List<Story> stories) {
    String title = '';
    stories.forEach((Story story) {
      if (title.isNotEmpty) {
        title += ', ';
      }
      title += story.title;
    });
    return title;
  }

  static DateTime _getClusterLastInteraction(List<Story> stories) {
    DateTime latestTime = new DateTime(1970);
    stories.forEach((Story story) {
      if (latestTime.isBefore(story.lastInteraction)) {
        latestTime = story.lastInteraction;
      }
    });
    return latestTime;
  }

  static Duration _getClusterCumulativeInteractionDuration(
      List<Story> stories) {
    Duration largestDuration = new Duration();
    stories.forEach((Story story) {
      if (largestDuration < story.cumulativeInteractionDuration) {
        largestDuration = story.cumulativeInteractionDuration;
      }
    });
    return largestDuration;
  }
}
